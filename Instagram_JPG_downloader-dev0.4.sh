#!/bin/bash
# Instagram JPG downloader		# Baixador de JPG do Instagram
# created on 2016 by Anders Bateva	# criado em 2016 por Anders Bateva

#apresentação
{
	clear;
	echo "Instagram JPG downloader - dev 0.4 (5 de julho de 2016)";
	echo "========================";
	echo "Informe o nome de usuário(a) (fica na URL em \"instagram.com/<nome>\");";
	echo "o script baixará todas as fotos (JPG) no tamanho original;";
	echo "para vídeos, serão baixadas apenas as miniaturas estáticas (JPG)...";
	echo "Será criado um diretório com este nome na localização atual do script.";
	read -p "> Conta-alvo: " nome;
	echo "----";
}

#confirmação de existência
wget --delete-after --no-cookies -q https://www.instagram.com/$nome/; #baixando índice
if [ $? -ne 0 ] #testando se o download do índice não deu certo
then #se não deu certo...
	echo "Não existe essa conta! Ou você digitou errado, ou a conta foi renomeada...";
else #se deu certo...
	echo -n "Conta encontrada! ";
	
	#gerência do diretório
	{
		if [ ! -d "$nome" ]
		then
			mkdir $nome; #criando diretório
		fi
		cd $nome; #entrando no diretório
	}
	
	contador_pagina=1; #contador do número da página atual, começa em 1
	total_videos=0;
	
	wget --no-cookies -q -O indice$contador_pagina.html https://www.instagram.com/$nome/; #baixando o index da conta, silenciosamente

	#confirmação de identidade
	{
		echo "É esta?"
		echo -n "| Nome: ";
		grep -o '"full_name": "[^"]*"' indice1.html | cut -d: -f2 | grep -o '".*"' | grep -o '[^"]*'; #extraindo Nome Completo
		echo -n "| Bio:  ";
		grep -o '"biography": "[^"]*"' indice1.html | cut -d: -f2 | grep -o '".*"' | grep -o '[^"]*'; #extraindo Biografia (pode ser null, pode ter quebra de linha, pode ter ":")
		echo "(sim = qualquer tecla; não = CTRL+C)";
		read;
		echo "Certo.";
	}
	#download da foto de perfil: HD se tiver, normal se não tiver HD
	{
		perfil_hd=$(grep -o '"profile_pic_url_hd": "https://scontent.cdninstagram.com/[a-z0-9/\._-]*\.jpg' indice1.html);
		if [ "$perfil_hd" == "" ] #checando se a foto de perfil é HD
		then #se não for
			grep -o '"profile_pic_url": "https://scontent.cdninstagram.com/[a-z0-9/\._-]*\.jpg' indice1.html | grep -o "https://scontent.cdninstagram.com/[a-z0-9/\._-]*\.jpg" > links.html;
		else #se for
			grep -o '"profile_pic_url_hd": "https://scontent.cdninstagram.com/[a-z0-9/\._-]*\.jpg' indice1.html | grep -o "https://scontent.cdninstagram.com/[a-z0-9/\._-]*\.jpg" > links.html;
		fi
	}
	#download das demais fotos do índice 1
	grep -o '"display_src": "https://scontent.cdninstagram.com/[a-z0-9/\._-]*\.jpg' indice$contador_pagina.html | grep -o "https://scontent.cdninstagram.com/[a-z0-9/\._-]*\.jpg" >> links.html; #extraindo links JPG e adicionando ao fim do arquivo de links - no futuro vai ter que pegar vídeo também!

	privada=$(grep -o ", \"is_private\": [a-z]*," indice1.html | grep -o -e true -e false); #verificando se a conta é privada ou não
	if [ $privada == 'true' ] #informando ao usuário se dará pra baixar ou não
	then
		echo "Infelizmente, a conta-alvo é privada. Não há o que este script possa fazer por você...";
		echo "(O Instagram só deixa os seguidores aprovados visualizarem fotos desse tipo de conta)";
	else # se a conta não for privada...
		 echo "Vai começar o download do(s) índice(s), e extração de endereços (URL) de fotos (JPG):";
		#impressão do cabeçalho da tabela de índices + índice 1
		{
			echo "--------------------------------------------";
			echo " Índice -  Total URLs   -   (Parcial vídeos)";
			echo "--------------------------------------------";
			echo -n " $contador_pagina      -";
			
			total_links=$(wc -l < links.html);
			echo -n "       $total_links      -";
			
			total_videos=$(grep -o ', "is_video": [a-z]*,' indice$contador_pagina.html | grep -o -c true);
			echo    "      ($total_videos)";
		}
		
		prox_pag=true; #só pra poder entrar no ciclo
		while $prox_pag == true #enquanto tiver próxima página...
		do
			prox_pag=$(grep -o ", \"has_next_page\": [a-z]*\}," indice$contador_pagina.html | grep -o -e true -e false); #verificando se o índice atual informa haver próximo índice
			if [ "$prox_pag" == "false" ] #há próxima página?
			then #informando ao usuário
				echo "--------------------------------------------";
				echo "Não detectada mais nenhuma página posterior.";
			else #baixa e processa a próxima página
				ult_img_pag=$(grep -o ", \"end_cursor\": \"[0-9]*\"," indice$contador_pagina.html | grep -o "[0-9]*"); # extraindo da página atual o código da próxima (é a última imagem da página atual)
				(( contador_pagina++ ));
				
				wget --no-cookies -q -O indice$contador_pagina.html https://www.instagram.com/$nome/?max_id=$ult_img_pag; #baixando próximo índice
				echo -n " $contador_pagina      -";
				
				grep -o '"display_src": "https://scontent.cdninstagram.com/[a-z0-9/\._-]*\.jpg' indice$contador_pagina.html | grep -o "https://scontent.cdninstagram.com/[a-z0-9/\._-]*\.jpg" >> links.html; #extraindo links JPG e adicionando ao fim do arquivo de links - no futuro vai ter que pegar vídeo também!
				total_links=$(wc -l < links.html);
				echo -n "       $total_links      -";
				
				total_videos=$(grep -o ', "is_video": [a-z]*,' indice$contador_pagina.html | grep -o -c true);
				echo    "      ($total_videos)";
			fi
		done

	total_links=$(wc -l < links.html);
	echo "Extraídas $total_links URLs (de JPGs) de $contador_pagina página(s) de índice. Com o(s) vídeo(s), nada será feito.";
	sleep 3;
	
	#passo 2 - baixar as fotos extraídas
	{
		echo;
		echo "Começando a baixar as $total_links imagens (JPGs)... Se nada acontecer, não há novas fotos.";
		sleep 3;
		wget --show-progress --progress=bar:noscroll -nc --no-cookies -q -i links.html; #silenciosamente, sem sub-diretórios, sem cookie, sem scroll, e sem cobbler
	}

	fi #se a conta é privada ou não
fi #se a conta existe ou não

#despedida
echo;
echo "Concluído! Fim de execução.";
echo "----";

###
# A melhorar no futuro (to-do):
# * o script não consegue baixar os vídeos - não tá legal;
# * o script precisa identificar se a Bio é nula, afinal, é opcional e buga a interface se estiver vazia;
# * o script poderia checar se o número de mídias encontradas por ele coincide com o total declarado pelos índices...
###
#135 linhas
