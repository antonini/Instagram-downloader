# Instagram-downloader
Esse é um shell script para Bash, destinado a baixar fotos da conta no Instagram que você indicar. Basta rodar o script e ele vai pedir o nome da conta-alvo, depois confirmar se a conta-alvo realmente é a que você indicou, e tudo o mais correrá tranquilamente sem precisar de novas interações com você. Se você rodar o script mais de uma vez para a mesma conta, ele vai baixar só as fotos novas, inteligentemente (portanto, não renomeie os arquivos, ou o script vai baixar tudo de novo).

Sendo um shell script, a ideia é que você tenha um sistema operacional GNU/Linux (ou seja, não o Windows), abra o terminal e use-o para invocar o script. Você deve ter uma conexão à internet, obviamente. Se alguma coisa der errado, não deixe de me relatar.

## Anonimato?
Não é necessário entrar usuário e senha, e consequentemente o script baixa apenas conteúdo de contas públicas. Não vejo benefício em fazer diferente disto. O propósito é poupar todo o trabalho manual de abrir cada foto em tamanho máximo, baixar e passar para a próxima, não "hackear" o sistema para puxar fotos privadas. Igualmente, o propósito não é fazer tudo por dentro da API do Instagram, e assim exigir que a pessoa crie/use uma conta e seja rastreada.

Os comandos de download estão todos configurados para não usarem os cookies de seu navegador; assim o script não entrega diretamente quem está baixando as fotos. Mas, se você rodar o script da sua casa, vai ser possível que alguém associe esse IP com a sua conta, e sua conta com sua identidade. Para ocultar seu IP "real", medidas externas ao script são necessárias, que cabem ao usuário interessado analisar.

Ainda assim, o script entrega informações "básicas" como resolução da tela, sistema operacional, etc e "navegador"; ou seja, ele avisa que não é um navegador, mas um programa de download. Eu não vejo benefício em fazer diferente disto; mas se alguém tiver um motivo, pode me explicar.
