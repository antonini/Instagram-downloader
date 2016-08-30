# Instagram-downloader
## O que é?
Shell script (bash) para baixar fotos em contas "públicas" do Instagram que o usuário determinar. Como apenas conteúdo público é baixado, não é necessário ter conta no Instagram (e usar cookies/login), e eu creio que isso é uma vantagem!

## Como usar?
Basta rodar o script e ele vai pedir o nome da conta-alvo, depois confirmar se a conta-alvo realmente é a que você indicou, e tudo o mais correrá tranquilamente sem precisar de novas interações com você. Se você rodar o script mais de uma vez para a mesma conta, ele vai baixar só as fotos novas, inteligentemente (portanto, não renomeie os arquivos, ou o script vai baixar tudo de novo).

Caso você sinta necessidade de mais detalhes, pode ler o código e os comentários no código, e assim entender melhor...

## Requisitos
Sendo um shell script, a ideia é que você tenha um sistema operacional GNU/Linux (ou seja, não o Windows), abra o terminal e use-o para invocar o script. Você deve ter uma conexão à internet, obviamente. Se alguma coisa der errado, não deixe de me relatar (bug report).

## Anonimato?
Nem sim, nem não.

<table>
<tr>
<th colspan="2">Exemplo de informações entregues para o Instagram nos downloads:</th>
</tr>
<tr>
<th width="50%">Seu navegador</th>
<th width="50%">Esse script</th>
</tr>
<tr>
<td>"Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.9.2.12) Gecko/20101026 Firefox/3.6.12"</td>
<td>"Wget"</td>
</tr>
<tr>
<td>Endereço IP "255.255.255.255"</td>
<td>Endereço IP "255.255.255.255"</td>
</tr>
<tr>
<td>Cookie "dbfdg5d776df6sfsf7d78s"</td>
<td>---</td>
</tr>
</table>

Vê-se que, com o script, muito menos informações identificadoras são enviadas (os cookies são especialmente problemáticos, pois são códigos únicos). As duas informações entregues o são porquê: 1) IP não cabe ao script ocultar; 2) o comando wget para download é ele próprio e não vejo porquê ocultar. O site sendo acessado porém, pode até mesmo descobrir mais detalhes do sistema do usuário, creio que com JavaScript (resolução da tela, tempo de visita, origem e destino, etc).

Note porém, que informações ainda podem ser deduzidas no caso do script! Essas seriam informações comportamentais do usuário executando o script, como o horário de uso e as contas-alvo (ou uma categoria onde as contas possam ser agrupadas, como o sexo ou país). O script mesmo tem um comportamento próprio pertinente à sua versão, por exemplo, ignorar os vídeos (versões bem do começo) ou baixar todos os índices todas as vezes (algumas versões depois).

No fim, ainda é melhor que o navegador.
