#!/bin/bash
# Instagram Downloader			# Baixador de Instagram
# created on 2016 by Anders Bateva	# criado em 2016 por Anders Bateva
# https://github.com/andersbateva/Instagram-downloader

function linha_horizontal { printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -; }

function extrair_foto {	grep -o '"'$1'": "https://[a-z0-9/\._-]*\.jpg' indice$2.html | cut -d'"' -f4; } #Curiosidade: terminar o link como .jpg.html faz uma arte ASCII da foto.

function extrair_video { grep -o '"'video_url'": "https://[a-z0-9/\._-]*\.mp4' $1 | cut -d'"' -f4; }

function extrair_codigo_video { #MELHORAR: realmente só extrair o vídeo, e não fazer toda essa manipulação de objeto JS
	local videos_indice=$(grep -o '"is_video": true,' indice$1.html | wc -l); #contagem de vídeos no índice
	
	if [ $videos_indice -gt 0 ] #sem vídeos no índice, sem extração
	then
		local videos_indice_extraidos=0;
		local campo_processar=1;
		
		while [ $campo_processar -le 12 ]
		do
			local objeto_atual=$(grep -oP '(?<={"code":).*?(?=}, {"code":|}]},)' indice$1.html | cut -d$'\n' -f$campo_processar);
			local is_video=$(echo $objeto_atual | grep -o '"is_video": true' | grep -o true);
			
			if [ "$is_video" == "true" ] #se o objeto atual é um vídeo...
				then echo $objeto_atual | cut -d'"' -f2;
			fi

			(( campo_processar++ ));
		done
	fi
}

function linha_tabela_indices { #INDENTAR A TABELA 1 ESPAÇO
	local total_videos=0;
	echo -n "    $1    -"; # $1 é o índice atual

	extrair_foto display_src $1 >> Fotos.txt;
	local total_fotos=$(wc -l < Fotos.txt);
	(( total_fotos-- ));
	echo -n "      $total_fotos     -";

	extrair_codigo_video $1 >> Codigos_Videos.txt
	local total_videos=$(wc -l < Codigos_Videos.txt);
	echo    "      $total_videos ";
}

function baixar_fotos {
	linha_horizontal;
	echo "Começando a baixar as imagens (JPGs)... Se nada acontecer, não há novas fotos.";
	sleep 3;
	wget --show-progress --progress=bar:noscroll -nc --no-cookies -q -i Fotos.txt; #silenciosamente, sem sub-diretórios, sem cookie, sem scroll, e sem cobbler
}

function baixar_videos {
	{ #gerência do diretório "Videos"
		if [ ! -d "Videos" ]
		then mkdir Videos; #criando diretório
		fi
		cd Videos; #entrando no diretório
	}
	
	while read line #acrescentar a URL antes do código, para poder baixar as páginas dos vídeos
	do
    	echo "https://www.instagram.com/p/$line" >> Paginas_Videos.txt;
	done < ../Codigos_Videos.txt
	
	linha_horizontal;
	echo "Começando a baixar os vídeos  (MP4s)... Se nada acontecer, não há novos vídeos.";
	sleep 3;
	wget -nc --no-cookies -q -i Paginas_Videos.txt; #silenciosamente, sem sub-diretórios, sem cookie, e sem cobbler
	
	while read line
	do
    	extrair_video $line >> URLs_Videos.txt;
	done < ../Codigos_Videos.txt
	
	wget --show-progress --progress=bar:noscroll -nc --no-cookies -q -i URLs_Videos.txt; #silenciosamente, sem sub-diretórios, sem cookie, sem scroll, e sem cobbler
}

function baixar_indices {
	rm -f Codigos_Videos.txt; #deletando a lista de IDs de vídeos, para zerar esse contador
	
	local contador_pagina=1; #contador de página atual
	local prox_pag=true; #só pra poder entrar no ciclo pela primeira vez
	while $prox_pag == true #enquanto tiver próxima página...
	do
		linha_tabela_indices $contador_pagina;
		prox_pag=$(grep -o ", \"has_next_page\": [a-z]*\}," indice$contador_pagina.html | grep -o -e true -e false); #verificando se o índice atual informa haver próximo índice

		if [ "$prox_pag" == "false" ] #há próxima página?
		then #informando ao usuário
			echo " -------------------------------------";
			echo "Nenhuma página posterior detectada.";
		else #baixa e processa a próxima página
			local ult_img_pag=$(grep -o ", \"end_cursor\": \"[0-9]*\"," indice$contador_pagina.html | grep -o "[0-9]*"); # extraindo da página atual o código da próxima (é a última imagem da página atual)
			(( contador_pagina++ )); #define a próxima (incrementa)
			wget --no-cookies -q -O indice$contador_pagina.html https://www.instagram.com/$nome/?max_id=$ult_img_pag; #baixando próximo índice
		fi
	done
	
	local total_fotos=$(wc -l < Fotos.txt);
	local total_videos=$(wc -l < Codigos_Videos.txt);
	echo "Extraídas $total_fotos foto(s) e $total_videos vídeo(s) de $contador_pagina página(s) de índice."; #é preciso explicar pois tem a foto de perfil, e portanto a conta de quantas fotos há não coincide. E os vídeos não são fotos!
}

function prompt_nome_da_conta {
	clear;
	echo "Instagram Downloader - dev 0.5 (1 de agosto de 2016)";
	printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' =;
	echo "Informe o nome da conta-alvo. O script baixará todas as mídias dentro de uma pasta.";
	echo "* o nome da conta fica na URL em \"instagram.com/<nome>\";";
	echo "* as mídias são fotos (JPG) e vídeos (MP4);";
	read -p "> Conta-alvo: " nome;
	linha_horizontal;
}

function verificar_conta_existe {
	wget --delete-after --no-cookies -q https://www.instagram.com/$nome/; #baixando índice
	
	if [ $? -ne 0 ] #testando se o download do índice não deu certo
	then #se não deu certo (retornos 1~8)...
		echo "Parece que a conta não existe! Possibilidades:";
		echo "* você digitou o nome errado;";
		echo "* o nome foi certo em alguma época, mas a conta foi renomeada;";
		echo "* você está com problemas na sua conexão de internet!";
		despedida;
	else
		echo -n "Conta encontrada! ";  #se deu certo (retorno 0 do wget)...
		return 0;
	fi
}

function confirmar_identidade {
	echo "É esta?";
	
	echo -n " | Nome  : ";
	echo -e $(grep -o '"full_name": "[^"]*"' indice1.html | cut -d: -f2 | grep -o '".*"' | grep -o '[^"]*');
	
	echo -n " | Bio   : ";
	local bio=$(grep -o '"biography": "[^"]*"' indice1.html | cut -d: -f2- | cut -d' ' -f2-);
	if [ "$bio" == "" ] #pra não dar erro em biografia vazia...
	then echo " ";
	else echo -e $bio;
	fi
		
	echo -n " | Midias: ";
	midias=$(grep -o '"media": {"count": [0-9]*,' indice1.html | grep -o '[0-9]*');
	echo $midias;
	echo "(sim = qualquer tecla; não = CTRL+C)";
	read -p "> ";
	echo "Certo.";
	linha_horizontal;
}

function extrair_foto_perfil { #extração da foto de perfil: HD se tiver, normal se não tiver HD
	local perfil_hd=$( extrair_foto profile_pic_url_hd 1);
	if [ "$perfil_hd" == "" ]
	then extrair_foto profile_pic_url 1 > Fotos.txt;
	else extrair_foto profile_pic_url_hd 1 > Fotos.txt;
	fi
}

function verificar_conta_privada {
	local privada=$(grep -o ", \"is_private\": [a-z]*," indice1.html | grep -o -e true -e false); #verificando se a conta é privada ou não
	if [ $privada == 'true' ] #informando ao usuário se dará pra baixar ou não
	then
		echo "Conta privada! Infelizmente, não há o que este script possa fazer por você...";
		echo "(O Instagram só deixa os seguidores aprovados visualizarem fotos desse tipo de conta)";
		despedida;
	else # se a conta não for privada...
		return 0; #prosseguir com o script
	fi
}

function verificar_conta_zerada {
	if [ $midias -eq 0 ]
	then
		echo "Conta zerada! Sem nenhuma mídia, o script não tem o que fazer.";
		despedida;
	else # se a conta tiver pelo menos 1 foto
		echo "Vai começar o download do(s) índice(s), e extração de endereços (URL) das mídias:";
		return 0; #prosseguir com o script
	fi
}

function despedida {
	echo;
	echo "Concluído sem sucesso.";
	linha_horizontal;
	exit 1;
}

function main {
	prompt_nome_da_conta;   #solicita o nome da conta-alvo para o usuário
	verificar_conta_existe; #se a conta informada não existe, o script encerra-se
	
	# se a conta existe, cria-se o diretório
	{ #gerência do diretório
		if [ ! -d "$nome" ]
		then mkdir $nome; #criando diretório
		fi
		cd $nome; #entrando no diretório
	}
	
	wget --no-cookies -q -O indice1.html https://www.instagram.com/$nome/; #baixando o indice1 da conta, silenciosamente
	#MELHORAR: baixar dentro de um diretório "Índices", pra não misturar Índices com Fotos.
	
	confirmar_identidade; #se a conta está errada, o usuário encerra o script
	extrair_foto_perfil;  #se a conta está certa , baixa a foto de perfil
	
	#antes de baixar o resto das fotos, impedir alguns erros:
	verificar_conta_privada; #se a conta é privada, o script encerra-se
	verificar_conta_zerada;  #se a conta é zerada , o script encerra-se
	
	#impressão da tabela de índices baixados
	{
		echo " -------------------------------------";
		echo "  Índice - Total fotos - Total vídeos ";
		echo " -------------------------------------";
		baixar_indices;
		#MELHORAR: o script deveria baixar só os primeiros índices, e não todos, quando já tiver rodado uma vez pra mesma conta (fotos novas ficam sempre nos primeiros índices!)
	}
	sleep 3;
	baixar_fotos;
	baixar_videos;
	#MELHORAR: o script poderia checar se o número de mídias encontradas por ele coincide com o total declarado pelo Instagram...
	linha_horizontal;
	echo "Concluído com sucesso!";
	echo "Quando você rodar o script da próxima vez, só as mídias novas serão baixadas.";
}
main;


#235 linhas
