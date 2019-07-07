window.addEventListener("load", function() {

    
    // restaga formulário de produtos
    let form = document.getElementById("addProducts");

    // adiciona uma função para
    // fazer o login quando o 
    // formulário for submetido
    form.addEventListener('submit', addProduct);
})

function addProduct() {

    // previne a página de ser recarregada
    event.preventDefault();

    $('#load').attr('disabled', 'disabled');

    // resgata os dados do formulário
    let nome = $("#nome").val();
    let endereco = $("#endereco").val();
    let cpf = $("#cpf").val();

    // envia a requisição para o servidor
    $.post("/addProducts", {nome: nome, endereco: endereco, cpf: cpf}, function(res) {
        
        console.log(res);
        // verifica resposta do servidor
        if (!res.error) {
            console.log("*** Views -> js -> produtos.js -> addProduct: ***", res.msg);            
            // limpa dados do formulário
            $("#nome").val("");
            $("endereco").val("");
            $("#cpf").val("");
            
            // remove atributo disabled do botao
            $('#load').attr('disabled', false);

            alert("Seu paciente foi cadastrado com sucesso");
        } else {
            alert("Erro ao cadastrar paciente. Por favor, tente novamente mais tarde. " + res.msg);
        }

    });
    
}