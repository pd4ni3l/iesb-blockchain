pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

contract MyContract {

    // evento para notificar o cliente que a conta foi atualizada
    event userRegisted(address _addr, string newEmail);
    // evento para notificar o cliente que o produto foi registrado
    event PacienteRegistered(uint id);
    // evento para notificar o cliente de que a Etapa foi registrada
    event StageRegistered(uint[]);
    // evento para notificar o cliente de que um histórico foi registrado
    event historyRegistered(string _msg);
    // evento para notificar o cliente de que um produto foi atualizado
    event PacienteUpdated(uint _PacienteId, string _msg);

    // estrutura para manter dados do usuário
    struct User {
        string email;
    }

    // estrutura para registar o estagio de um produto
    struct Stage {
        uint id;
        uint[] pacientes;
        string desc;
        address owner;
    }

    // estrutura para manter dados do paciente
    // alterar desc para nome
    // alterar price para cpf
    // adicionar endereco
    struct Paciente {
        uint id;
        string nome;
        uint cpf;
        string endereco;
        address owner;
    }

    // estrutura para manter dados de um histórico
    struct History {
        uint PacienteId;
        string[] stageDesc;
        string[] dates;
        address PacienteOwner;
    }

    // mapeia um id a um produto
    mapping (uint => Paciente) pacientes;
    uint[] public pacientesIds;

    // mapeia um id a uma etapa
    mapping(uint => Stage) stages;
    uint[] public stagesIds;

    mapping (uint => History) histories;
    uint[] public historiesIds;
    uint[] public pacientesInHistory;

    // mapeia endereço do usuário a sua estrutura
    mapping (address => User) users;

    // state variables
    uint256 private lastId = 0;
    uint256 private stagesId = 0;
    uint256 private historyId = 0;

    // função para cadastrar conta do usuário
    function setUser(address _addr, string memory _email) public {
        User storage user = users[_addr];
        user.email = _email;

        // notifica o cliente através do evento
        emit userRegisted(_addr, "Conta registrada!");
    }

    // função para resgatar dados do usuário
    function getUser(address _addr) public view returns(string memory) {
        User memory user = users[_addr];
        return (user.email);
    }

    // função para cadastrar um paciente
    /*  uint id;
        string nome;
        uint cpf;
        string endereco;
        address owner; */
    function addPaciente(string memory _nome, uint _cpf, string memory _endereco) public {
        require(bytes(_nome).length >= 1, "Invalid name");
        require(_cpf > 0, "CPF must be higher than zero");
        require(bytes(_endereco).length >= 1, "Endereco não pode ser em branco");

        pacientes[lastId] = Paciente(lastId, _nome, _cpf, _endereco, msg.sender);
        pacientesIds.push(lastId);
        lastId++;
        emit PacienteRegistered(lastId);
    }

    function updatePaciente(uint _PacienteId, string memory _newDesc, uint _newPrice) public {
        require(bytes(_newDesc).length >= 1, "Invalid name");
        require(_newPrice > 0, "New price must be higher than zero");

        Paciente storage prod = pacientes[_PacienteId];

        require(prod.owner == msg.sender, "Only the owner can update the Paciente");
        prod.desc = _newDesc;
        prod.price = _newPrice;

        emit PacienteUpdated(_PacienteId, "Produto atualizado com successo");
    }

    // função para resgatar info de um produto
    function PacienteInfo(uint _id) public view
        returns(
            uint,
            string memory,
            address,
            uint
        ) {
            require(_id <= lastId, "Paciente does not exist");

            Paciente memory Paciente = pacientes[_id];

            return (
                Paciente.id,
                Paciente.desc,
                pacientes[_id].owner,
                Paciente.price
            );
    }

    // função que retorna todos os produtos de um usuário
    function getpacientes() public view returns(uint[] memory, string[] memory, address[] memory, uint[] memory) {

        uint[] memory ids = pacientesIds;

        uint[] memory idspacientes = new uint[](ids.length);
        string[] memory names = new string[](ids.length);
        address[] memory owners = new address[](ids.length);
        uint[] memory prices = new uint[](ids.length);

        for (uint i = 0; i < ids.length; i++) {
            (idspacientes[i], names[i], owners[i], prices[i]) = PacienteInfo(i);
        }

        return (idspacientes, names, owners, prices);
    }

    function isPacienteInHistory(uint _id) public view returns (bool) {
        for (uint i = 0; i < pacientesInHistory.length; i++) {
            if (pacientesInHistory[i] == _id)
                return true;
        }
        return false;
    }

    // função para adicionar o histórico de um produto
    function addNewHistory(uint _PacienteId, string[] memory _stageDesc, string[] memory _dates) public {
        require(_PacienteId >= 0, "invalid PacienteId");

        if (!isPacienteInHistory(_PacienteId)) {
            histories[historyId] = History(_PacienteId, _stageDesc, _dates, msg.sender);
            historiesIds.push(historyId);
            pacientesInHistory.push(_PacienteId);
            historyId++;
            emit historyRegistered("History saved!");
        } else {
            bool added = addToHistory(_PacienteId, _stageDesc, _dates);
            if (added) {
                emit historyRegistered("History saved!");
            }
        }
    }

    function addToHistory(uint _PacienteId, string[] memory _stageDesc, string[] memory _dates) public returns (bool) {
        uint size = historiesIds.length;
        for (uint i = 0; i < size; i++) {
            if (histories[i].PacienteId == _PacienteId) {
                History storage his = histories[i];
                his.stageDesc.push(_stageDesc[0]);
                his.dates.push(_dates[0]);
                return true;
            }
        }
        return false;
    }

    function HistoryInfo(uint _id) public view returns (uint, string[] memory, string[] memory, address) {
        require(_id <= historyId, "History does not exist");

        History memory his = histories[_id];
        return (
            his.PacienteId,
            his.stageDesc,
            his.dates,
            his.PacienteOwner
        );
    }

    function getHistories() public view returns (string[] memory, string[][] memory, string[][] memory, address[] memory) {
        uint[] memory ids = historiesIds;

        uint[] memory prodsIds = new uint[](ids.length);
        string[] memory pacientesNames = new string[](ids.length);
        string[][] memory stageDesc = new string[][](ids.length);
        string[][] memory dates = new string[][](ids.length);
        address[] memory addrs = new address[](ids.length);

        for (uint i = 0; i < ids.length; i++) {
            (prodsIds[i], stageDesc[i], dates[i], addrs[i]) = HistoryInfo(i);
            (, pacientesNames[i], ,) = PacienteInfo(prodsIds[i]);
        }

        return (pacientesNames, stageDesc, dates, addrs);
    }

    // função para adicionar produtos à um estágio
    function addToStage(uint[] memory _pacientesIds, string memory _stageDesc) public {
        require(bytes(_stageDesc).length >= 1, "Name invalid");
        require(_pacientesIds.length > 0, "Price must be higher than zero");

        stages[stagesId] = Stage(stagesId, _pacientesIds, _stageDesc, msg.sender);
        stagesIds.push(stagesId);
        stagesId++;

        emit StageRegistered(_pacientesIds);
    }

    // função para resgatar info de um estágio
    function stageInfo(uint _id) public view returns (uint, uint[] memory, string memory, address) {
        require(_id <= stagesId, "Paciente stage does not exist");

        Stage memory stage = stages[_id];
        return (stage.id, stage.pacientes, stage.desc, stage.owner);
    }

    // função que retorna todos os produtos de um usuário
    function getStages() public view returns (uint[] memory, uint[][] memory, string[] memory, address[] memory) {

        uint[] memory ids = stagesIds;
        uint[] memory idsStages = new uint[](ids.length);
        uint[][] memory prods = new uint[][](ids.length);
        string[] memory prods_nome = new string[](ids.length);
        address[] memory owners = new address[](ids.length);

        for(uint i = 0; i < ids.length; i++) {
            (idsStages[i], prods[i], prods_nome[i], owners[i]) = stageInfo(i);
        }

        return (ids, prods, prods_nome, owners);
    }

}