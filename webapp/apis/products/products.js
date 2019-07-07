const path = require('path');
const Web3 = require("web3");

const product_abi = require(path.resolve("../dapp/build/contracts/MyContract.json"));
const httpEndpoint = 'http://localhost:8540';

let contractAddress = require('../../utils/parityRequests').contractAddress;

const OPTIONS = {
    defaultBlock: "latest",
    transactionConfirmationBlocks: 1,
    transactionBlockTimeout: 5
};

let web3 = new Web3(httpEndpoint, null, OPTIONS);

let MyContract = new web3.eth.Contract(product_abi.abi, contractAddress);

module.exports = {
    renderAddProducts: function(req, res) {

        // verifica se usuario esta logado
        if (!req.session.username) {
            res.redirect('/api/auth');
            res.end();
        } else {
            res.render('produtos.html');
        }
    },
    renderGetProducts: function(req, res) {
        // verifica se usuario esta logado
        if (!req.session.username) {
            res.redirect('/api/auth');
            res.end();
        } else {
            res.render('listaProdutos.html');
        }
    },
    renderEditProduct: function(req, res) {
        // verifica se usuario esta logado
        if (!req.session.username) {
            res.redirect('/api/auth');
            res.end();
        } else {
            res.render('editProduct.html');
        }
    },
    getProducts: async function(req, res) {
        console.log(contractAddress)
        let userAddr = req.session.address;
        console.log("*** Getting products ***", userAddr);

        await MyContract.methods.getProducts()
            .call({ from: userAddr, gas: 3000000 })
            .then(function (prod) {

                console.log("prod", prod);
                if (prod === null) {
                    return res.send({ error: false, msg: "no products yet"});
                }

                let produtos = [];
                for (i = 0; i < prod['0'].length; i++) {
                    produtos.push({ 'id': +prod['0'][i], 'nome': prod['1'][i], 'endereco': prod['2'][i], 'cpf': +prod['3'][i], 'addr': prod['4'][i] });
                }

                console.log("produtos", produtos);

                res.send({ error: false, msg: "produtos resgatados com sucesso", produtos});
                return true;
            })
            .catch(error => {
                console.log("*** productsApi -> getProducts ***error:", error);
                res.send({ error: true, msg: error});
            })
        
    },
    addProducts: async function(req, res) {

        if (!req.session.username) {
            res.redirect('/');
            res.end();
        } else {
            console.log("*** ProductsApi -> AddProducts ADD***");
            console.log(req.body);

            let nome = req.body.nome;
            let endereco = req.body.endereco;
            let cpf = req.body.cpf;
            let userAddr = req.session.address;
            let pass     = req.session.password;

            try {
                let accountUnlocked = await web3.eth.personal.unlockAccount(userAddr, pass, null)
                if (accountUnlocked) {

                    await MyContract.methods.addProduct(nome, endereco, cpf)
                        .send({ from: userAddr, gas: 3000000 })
                        .then(function(result) {
                            console.log(result);
                            return res.send({ 'error': false, 'msg': 'Paciente cadastrado com sucesso.'});  
                        })
                        .catch(function(err) {
                            console.log(err);
                            return res.send({ 'error': true, 'msg': 'Erro ao comunicar com o contrato.'});
                        })
                } 
            } catch (err) {
                return res.send({ 'error': true, 'msg': 'Erro ao desbloquear sua conta. Por favor, tente novamente mais tarde.'});
            }
        }
    },
    updateProduct: async (req, res) => {
        
        if (!req.session.username) {
            res.redirect('/');
            res.end();
        } else {
        
            let productId = req.body.productId;
            let newNome   = req.body.newNome;
            let newEndereco = req.body.newEndereco;
            let newCpf  = req.body.newCpf;
            let userAddr  = req.session.address;
            let pass      = req.session.password;

            console.log("apis -> products -> updateProduct: ", userAddr, productId, newNome, newEndereco, newCpf);

            try {
                let accountUnlocked = await web3.eth.personal.unlockAccount(userAddr, pass, null)
                console.log("Account unlocked?", accountUnlocked);
                if (accountUnlocked) {

                    await MyContract.methods.updateProduct(productId, newDesc, newPrice)
                        .send({ from: userAddr, gas: 3000000 })
                        .then(receipt => {
                            console.log(receipt);
                            return res.send({ 'error': false, 'msg': 'Paciente atualizado com sucesso.'}); 
                        })
                        .catch((err) => {
                            console.log(err);
                            return res.json({ 'error': true, msg: "erro ao se comunar com o contrato"});
                        })
                }
            } catch (error) {
                return res.send({ 'error': true, 'msg': 'Erro ao desbloquear sua conta. Por favor, tente novamente mais tarde.'});
            }
        }
    }
}