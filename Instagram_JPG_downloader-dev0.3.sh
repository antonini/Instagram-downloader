#!/bin/bash
# Instagram JPG downloader		# Baixador de JPG do Instagram
# created on 2016 by Anders Bateva	# criado em 2016 por Anders Bateva

#apresentação
{
	echo "Instagram JPG downloader - dev 0.3 (4 de julho de 2016)";
	echo "================";
	echo -n "Descrição: este script destina-se a baixar todas as fotos de um(a) determinado(a) usuário(a) do Instagram, uma vez por foto (ou seja, o arquivo original, e não a miniatura). ";
	echo "Vídeos AINDA não são suportados direito (o script baixa só a miniatura JPG).";
	echo "----";
	echo -n "Insira o nome de usuário(a) que consta na URL da página de perfil. Fica em \"https://www.instagram.com/<nome de usuário(a)>\". ";
	echo "Será criado um diretório com este nome na localização atual, e dentro serão salvos os arquivos baixados.";
	read -p "Usuário(a)-alvo: " nome; #eu podia testar se o nome de usuário existe, em primeiro lugar, né?
	echo "----";
}

mkdir $nome; #criando diretório ... não dá pra criar e entrar de uma vez?
cd $nome; #entrando no diretório ... não dá pra criar e entrar de uma vez?

{
	contador_pagina=1; #contador do número da página atual, começa em 1

	wget -nd -q -O indice$contador_pagina.html https://www.instagram.com/$nome/; #baixando o index da conta, silenciosamente, sem sub-diretórios
	echo "1) Baixado índice da página $contador_pagina...";
	#confirmação de identidade
	{
		echo "|Confirmação: é realmente este o(a) usuário(a)-alvo?"
		echo -n "|   Nome: ";
		grep -o '"full_name": "[^"]*"' indice1.html | cut -d: -f2 | grep -o '".*"' | grep -o '[^"]*'; #extraindo Nome Completo
		echo -n "|   Bio:  ";
		grep -o '"biography": "[^"]*"' indice1.html | cut -d: -f2 | grep -o '".*"' | grep -o '[^"]*'; #extraindo Biografia (pode ser null, pode ter quebra de linha, pode ter ":")
		echo "|(sim = qualquer tecla; não = CTRL+C)";
		read;
	}
	#download da foto de perfil: HD se tiver, normal se não tiver HD
	{
		perfil_hd=$(grep -o '"profile_pic_url_hd": "https://scontent.cdninstagram.com/[a-z0-9/\._-]*\.jpg' indice1.html);
		if test "$perfil_hd" == "" #checando se a foto de perfil é HD
		then #se não for
			grep -o '"profile_pic_url": "https://scontent.cdninstagram.com/[a-z0-9/\._-]*\.jpg' indice1.html | grep -o "https://scontent.cdninstagram.com/[a-z0-9/\._-]*\.jpg" >> links.html;
		else #se for
			grep -o '"profile_pic_url_hd": "https://scontent.cdninstagram.com/[a-z0-9/\._-]*\.jpg' indice1.html | grep -o "https://scontent.cdninstagram.com/[a-z0-9/\._-]*\.jpg" >> links.html;
		fi
	}
	grep -o '"display_src": "https://scontent.cdninstagram.com/[a-z0-9/\._-]*\.jpg' indice$contador_pagina.html | grep -o "https://scontent.cdninstagram.com/[a-z0-9/\._-]*\.jpg" >> links.html; #extraindo links JPG e adicionando ao fim do arquivo de links - no futuro vai ter que pegar vídeo também!

	privada=$(grep -o ", \"is_private\": [a-z]*," indice1.html | grep -o -e true -e false); #verificando se a conta é privada ou não
	if test $privada == 'true' #informando ao usuário se dará pra baixar ou não
	then
		echo "Infelizmente, a conta-alvo é privada (a única foto visível é a do perfil). Não há o que este script possa fazer por você...";
	else # se a conta não for privada...

		total_links=$(wc -l < links.html);
		echo -n "1.$contador_pagina) Detectado índice da página $contador_pagina...";
		echo -n " baixado...";
		echo " links extraídos - total: $total_links;";

		prox_pag=true; #só pra poder entrar no ciclo
		while $prox_pag == true #enquanto tiver próxima página...
		do
			prox_pag=$(grep -o ", \"has_next_page\": [a-z]*\}," indice$contador_pagina.html | grep -o -e true -e false); #verificando se o índice atual informa haver próximo índice
			if test $prox_pag == 'false' #informando ao usuário se há próxima página
			then
				echo "Não detectado mais nenhum índice de página posterior.";
			else
				ult_img_pag=$(grep -o ", \"end_cursor\": \"[0-9]*\"," indice$contador_pagina.html | grep -o "[0-9]*"); # extraindo da página atual o código da próxima (é a última imagem da página atual)
				contador_pagina=$(( contador_pagina + 1 )); #o ++ não funcionou!
				echo -n "1.$contador_pagina) Detectado índice da página $contador_pagina...";
				wget -nd -q -O indice$contador_pagina.html https://www.instagram.com/$nome/?max_id=$ult_img_pag; #baixando próximo índice
				echo -n " baixado...";
				grep -o '"display_src": "https://scontent.cdninstagram.com/[a-z0-9/\._-]*\.jpg' indice$contador_pagina.html | grep -o "https://scontent.cdninstagram.com/[a-z0-9/\._-]*\.jpg" >> links.html; #extraindo links JPG e adicionando ao fim do arquivo de links - no futuro vai ter que pegar vídeo também!
				total_links=$(wc -l < links.html);
				echo " links extraídos - total: $total_links;";
			fi
		done

	total_links=$(wc -l < links.html);
	echo "Extraídos $total_links links (de JPGs) de $contador_pagina páginas de índice.";

	#passo 2 - baixar as fotos extraídas
	{
		echo -n "2) Começando a baixar as $total_links imagens (JPGs) linkadas...";
		wget -q -i links.html; #silenciosamente, sem sub-diretórios
		echo " concluído!";
	}

	fi #se a conta é privada ou não
}

#despedida
{ 
	echo "Fim de execução.";
	echo "----";
	echo "A melhorar no futuro (to-do):";
	echo "* o script não consegue baixar os vídeos - não tá legal;";
	echo "* o script poderia detectar se o nome de usuário(a) realmente existe...";
	echo "----";
}
#100 linhas
