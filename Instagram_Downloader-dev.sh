#!/bin/bash
# Instagram Downloader				# Baixador de Instagram
# created on 2016 by Anders Bateva	# criado em 2016 por Anders Bateva
# https://github.com/andersbateva/Instagram-downloader

#apresentação
{
	clear;
	echo "Instagram Downloader - dev 0.4.1 (7 de julho de 2016)";
	echo "======================";
	echo "Informe o nome de usuário(a) (fica na URL em \"instagram.com/<nome>\");";
	echo "o script baixará todas as fotos (JPG) no tamanho original;";
	echo "para vídeos, serão baixadas apenas as miniaturas estáticas (JPG)...";
	echo "Será criado um diretório com este nome na localização atual do script.";
	read -p "> Conta-alvo: " nome;
	echo "-------------";
}

#função de extração de URLs de fotos (JPG)
function extrair_foto { #não consegue extrair URLs de alguma área do Brasil
	grep -o '"'$1'": "https://[a-z0-9/\._-]*\.jpg' indice$2.html | cut -d'"' -f4;
	#Curiosidade: terminar o link como .jpg.html faz uma arte ASCII da foto.
}

#função de impressão das linhas da tabela de índices
function linha_tabela_indices {
	echo -n "   $1    -";

	extrair_foto display_src $1 >> URLs.txt;
	total_URLs=$(wc -l < URLs.txt);
	(( total_URLs-- ));
	echo -n "      $total_URLs     -";

	total_videos=$(grep -o ', "is_video": [a-z]*,' indice$1.html | grep -o -c true);
	echo    "         ($total_videos)";
}

#confirmação de existência
wget --delete-after --no-cookies -q https://www.instagram.com/$nome/; #baixando índice

if [ $? -ne 0 ] #testando se o download do índice não deu certo
then #se não deu certo (retornos 1~8)...
	echo "Parece que a conta não existe! Possibilidades:";
	echo "* você digitou o nome errado;";
	echo "* o nome foi certo em alguma época, mas a conta foi renomeada;";
	echo "* você está com problemas na sua conexão de internet!";
else echo -n "Conta encontrada! ";  #se deu certo (retorno 0)...
	
	#gerência do diretório
	{
		if [ ! -d "$nome" ]
		then mkdir $nome; #criando diretório
		fi
		cd $nome; #entrando no diretório
	}
	
	contador_pagina=1; #contador de página atual
	total_videos=0;
	
	wget --no-cookies -q -O indice$contador_pagina.html https://www.instagram.com/$nome/; #baixando o indice1 da conta, silenciosamente

	#confirmação de identidade
	{
		echo "É esta?"
		
		echo -n "| Nome : ";
		echo -e $(grep -o '"full_name": "[^"]*"' indice1.html | cut -d: -f2 | grep -o '".*"' | grep -o '[^"]*');
		
		echo -n "| Bio  : ";
		bio=$(grep -o '"biography": "[^"]*"' indice1.html | cut -d: -f2- | cut -d' ' -f2-);
		if [ "$bio" == "" ] #pra não dar erro em biografia vazia...
		then echo " ";
		else echo -e $bio;
		fi
		
		echo -n "| Fotos: ";
		fotos=$(grep -o '"media": {"count": [0-9]*,' indice1.html | grep -o '[0-9]*');
		echo $fotos;
		echo "(sim = qualquer tecla; não = CTRL+C)";
		read -p "> ";
		echo "Certo.";
	}
	#extração da foto de perfil: HD se tiver, normal se não tiver HD
	{
		perfil_hd=$( extrair_foto profile_pic_url_hd $contador_pagina);
		if [ "$perfil_hd" == "" ]
		then extrair_foto profile_pic_url $contador_pagina > URLs.txt;
		else extrair_foto profile_pic_url_hd $contador_pagina > URLs.txt;
		fi
	}

	privada=$(grep -o ", \"is_private\": [a-z]*," indice1.html | grep -o -e true -e false); #verificando se a conta é privada ou não
	if [ $privada == 'true' ] #informando ao usuário se dará pra baixar ou não
	then
		echo "Infelizmente, a conta-alvo é privada. Não há o que este script possa fazer por você...";
		echo "(O Instagram só deixa os seguidores aprovados visualizarem fotos desse tipo de conta)";
	else # se a conta não for privada...
		if [ $fotos -eq 0 ]
		then echo "O total de fotos nessa conta é ZERO. O script não tem o que fazer.";
		else # se a conta tiver postado alguma foto alguma vez
			echo "Vai começar o download do(s) índice(s), e extração de endereços (URL) de fotos (JPG):";
			#impressão do cabeçalho da tabela de índices
			{
				echo "--------------------------------------------";
				echo " Índice -  Total URLs -   (Parcial vídeos)  ";
				echo "--------------------------------------------";
			}
			
			prox_pag=true; #só pra poder entrar no ciclo pela primeira vez
			while $prox_pag == true #enquanto tiver próxima página...
			do
				linha_tabela_indices $contador_pagina;
			
				prox_pag=$(grep -o ", \"has_next_page\": [a-z]*\}," indice$contador_pagina.html | grep -o -e true -e false); #verificando se o índice atual informa haver próximo índice
				if [ "$prox_pag" == "false" ] #há próxima página?
				then #informando ao usuário
					echo "--------------------------------------------";
					echo "Não detectada mais nenhuma página posterior.";
				else #baixa e processa a próxima página
					ult_img_pag=$(grep -o ", \"end_cursor\": \"[0-9]*\"," indice$contador_pagina.html | grep -o "[0-9]*"); # extraindo da página atual o código da próxima (é a última imagem da página atual)
					(( contador_pagina++ )); #define a próxima (incrementa)
					wget --no-cookies -q -O indice$contador_pagina.html https://www.instagram.com/$nome/?max_id=$ult_img_pag; #baixando próximo índice
				fi
			done
			
			total_URLs=$(wc -l < URLs.txt);
			echo "Extraídas $total_URLs URLs (de JPGs) de $contador_pagina página(s) de índice. Com o(s) vídeo(s), nada será feito.";
			sleep 3;
	
			#passo 2 - baixar as fotos extraídas
			{
				echo;
				if [ $total_URLs -eq 0 ] #vendo se foi extraída alguma URL.
				then echo "Estranho, não foi extraída nenhuma URL? Deve ser um erro...";
				else
					echo "Começando a baixar as $total_URLs imagens (JPGs)... Se nada acontecer, não há novas fotos.";
					sleep 3;
					wget --show-progress --progress=bar:noscroll -nc --no-cookies -q -i URLs.txt; #silenciosamente, sem sub-diretórios, sem cookie, sem scroll, e sem cobbler
				fi #se foi extraída alguma URL ou não
			}
		fi # se a conta postou alguma foto ou não
	fi #se a conta é privada ou não
fi #se a conta existe ou não

#despedida
echo;
echo "Concluído! Fim de execução.";
echo "----";

###
# A melhorar no futuro (to-do):
# * o script deveria baixar só os primeiros índices, e não todos, quando já tiver rodado uma vez praquela conta (fotos novas ficam sempre nos primeiros índices);
# * o script não consegue baixar os vídeos - não tá legal;
# * o script poderia checar se o número de mídias encontradas por ele coincide com o total declarado pelos índices...
###
