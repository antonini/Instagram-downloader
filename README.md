# Instagram-downloader
## O que é?
Shell script (bash) para baixar fotos em contas "públicas" do Instagram que o usuário determinar. Como apenas conteúdo público é baixado, não é necessário ter conta no Instagram (e usar cookies/login), e eu creio que isso é uma vantagem!

## Como usar?
Basta rodar o script e ele vai pedir o nome da conta-alvo, depois confirmar se a conta-alvo realmente é a que você indicou, e tudo o mais correrá tranquilamente sem precisar de novas interações com você. Se você rodar o script mais de uma vez para a mesma conta, ele vai baixar só as fotos novas, inteligentemente (portanto, não renomeie os arquivos, ou o script vai baixar tudo de novo).

Caso você sinta necessidade de mais detalhes, pode ler o código e os comentários no código, e assim entender melhor...

## Requisitos
Sendo um shell script, a ideia é que você tenha um sistema operacional GNU/Linux (ou seja, não o Windows), abra o terminal e use-o para invocar o script. Você deve ter uma conexão à internet, obviamente. Se alguma coisa der errado, não deixe de me relatar (bug report).

## Anonimato?
Ao passo que o script não informa diretamente quem está baixando, através de cookies/login, ele não confere pleno anonimato a quem o usa. Outros dados podem permitir deduções sobre que programa está acessando o site do Instagram, e mesmo quem está usando o programa. Nada diferente de qualquer navegador WEB... Afinal, o propósito é poupar todo o trabalho manual de abrir cada foto em tamanho máximo, baixar e passar para a próxima, não "hackear" o sistema para puxar fotos "privadas".

Detalho abaixo informações que são entregues. Se alguém se espantar, deveria seriamente repensar se continuará usando o cliente web/app de celular, pois são piores!
* endereço IP: se você rodar o script da sua casa, alguém pode analisar que quem usa esse IP é você. Para ocultar seu IP "real", medidas externas ao script são necessárias, que cabem ao usuário interessado analisar;
* informações "básicas": resolução da tela, sistema operacional, etc e "navegador" são entregues. Nesse "navegador" é que é entregue a informação que é um programa de download, mas apenas genericamente;
* comportamento: a velocidade entre a requisição de uma foto e outra, e mesmo o padrão de requisição de arquivos revelam 'sem querer' que se trata de um programa.

As informações "básicas" e o comportamento podem ser alterados no código, mas não vejo motivo/vantagem para tal; se você vê, pode discutir comigo ou fazer seu próprio fork. Quanto ao IP, como disse, não cabe num mero script, é solução externa.
