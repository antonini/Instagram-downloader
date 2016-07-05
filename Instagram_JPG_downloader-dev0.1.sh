# Instagram JPG downloader			# Baixador de JPG do Instagram
# created on 2016 by Anders Bateva	# criado em 2016 por Anders Bateva

echo "Instagram JPG downloader - dev 0.1 (2 de julho de 2016)";
echo "================";
echo "Descrição: este script destina-se a baixar todas as fotos de um(a) determinado(a) usuário(a) do Instagram. Vídeos AINDA não são suportados direito (o script baixa só a miniatura JPG).";
echo "----";
echo "Insira o nome de usuário(a) que consta na URL da página de perfil. Fica em \"https://www.instagram.com/<nome de usuário(a)>\". Será criado um diretório com este nome na localização atual, e dentro serão salvos os arquivos baixados.";
read nome;
echo "----";

mkdir $nome; #criando diretório ... não dá pra criar e entrar de uma vez?
cd $nome; #entrando no diretório ... não dá pra criar e entrar de uma vez?
wget -nd -q https://www.instagram.com/$nome/; #baixando o index da conta, silenciosamente, sem sub-diretórios
echo "1) Baixado o índice de fotos do(a) usuário(a) - index.html;";

grep -o https://scontent.cdninstagram.com/[a-z0-9/\._-]*\.jpg index.html > links.html; #extraindo os links das fotos (JPG) ... no futuro vai ter que pegar vídeo também!
echo "2) Extraídos os links das fotografias (JPG) constantes no índice - links.html;";

wget -q -i links.html; #baixando as imagens extraídas do índice, silenciosamente, sem sub-diretórios
echo "3) Baixadas as imagens extraídas do índice.";

echo "Concluído! Fim de execução.";
echo "----";
echo "A melhorar no futuro (to-do):";
echo "* o script só consegue baixar as 12 primeiras fotografias (página 1) - inaceitável!;";
echo "* o script não consegue baixar os vídeos - não tá legal;";
echo "* o script baixa várias vezes as mesmas imagens, em tamanhos diferentes - esquisito.";
echo "----";
# essa linha é só pra inteirar 30, hehehe