#!/bin/bash
# Instagram Downloader				# Baixador de Instagram
# created on 2016 by Anders Bateva	# criado em 2016 por Anders Bateva
# https://github.com/andersbateva/Instagram-downloader

function linha_horizontal { printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' $1; }

function extrair_foto {	grep -o '"'$1'": "https://[a-z0-9/\._-]*\.jpg' indice$2.html | cut -d'"' -f4; } #Curiosidade: terminar o link como .jpg.html faz uma arte ASCII da foto.

function extrair_video { grep -o '"'video_url'": "https://[a-z0-9/\._-]*\.mp4' $1 | cut -d'"' -f4; }  # erros por conta de códigos com  "-" acontecem aqui (grep).

function baixar_fotos {
	linha_horizontal -;
	echo " Começando a baixar as imagens (JPGs) de $nome...";
	echo;

	#impressão da "régua" de medir as barras de progresso
	{
		echo -n "0    .    ";
		local count=10;
		while (( count < 100 ))
		do
			echo -n "$count    .    ";
			(( count=$count+10 ));
		done
		echo -e "\b100";
	}
	
	local fotos_baixadas=0;
	while read line; do
		local OK=$(wget -nc --user-agent=$user_agent --no-cookies -q --show-progress --progress=bar:noscroll "$line" 2>&1 | grep -o '100%');
		   #silenciosamente, sem sub-diretórios, sem cookie, sem scroll, e sem cobbler
		if [ "$OK" == "100%" ]
		then
			if (( $(( fotos_baixadas % 500 )) == 0 && $fotos_baixadas > 0 )) # informa a cada 500 que deu 500...
			then echo -n " 500";
			fi
			if (( $(( fotos_baixadas % 100 )) == 0 && $fotos_baixadas > 0 )) # dá quebra de linha de 100 em 100 fotos
			then echo;
			fi
			if  [ $(( fotos_baixadas % 10 )) -eq 0 ] # dá espaço de 10 em 10 fotos
			then echo -n " ";
			fi
			echo -n "";
			(( fotos_baixadas++ ))
		fi
	done < Fotos.txt #foto de perfil já consta no arquivo
	echo; echo;
	echo "Fotos (novas) baixadas: $fotos_baixadas.";
	# LOG : gravar que foram baixadas $fotos_baixadas da conta $nome
}

function baixar_videos {
	gerencia_diretorio Videos;
	linha_horizontal -;
	rm -f Paginas_Videos.txt;
	echo " Começando a baixar os vídeos  (MP4s) de $nome... Se nada acontecer, não há novos vídeos.";
	
	while read line #acrescentar a URL antes do código, para poder baixar as páginas dos vídeos
	do
    	echo "https://www.instagram.com/p/$line" >> Paginas_Videos.txt;
	done < ../Codigos_Videos.txt
	
	local indices_videos_baixados=0;
	while read line; do
		wget -nc --user-agent=$user_agent --no-cookies -q "$line";
		(( indices_videos_baixados++ ));
		echo -n -e "\r Páginas de vídeo baixadas: $indices_videos_baixados";
	done < Paginas_Videos.txt
	echo;
	
	while read line
	do
    	extrair_video "$line" >> URLs_Videos.txt; # erros por conta de códigos com  "-" acontecem aqui (grep).
	done < ../Codigos_Videos.txt
	
	local videos_baixados=0;
	while read line; do
		echo -e " Vídeos baixados: $videos_baixados";
		wget -nc --user-agent=$user_agent --no-cookies -q --show-progress --progress=bar:noscroll "$line";
		# Nota: barra de progresso é o adequado para os vídeos. Eles são umas 20x maiores que as fotos (download demorado).
		if (( "$?" == "0" ))
		then
			tput cuu1; tput el; #sobe uma linha e apaga o conteúdo dela - barra de progresso.
			tput cuu1; tput el; #sobe uma linha e apaga o conteúdo dela - "vídeo baixados...".
		fi
		(( videos_baixados++ ));
	done < URLs_Videos.txt
	echo -e " Vídeos baixados: $videos_baixados"; #como isso é apagado a cada ciclo, no último tem que imprimir de novo
	
	cd ..; #Saindo da pasta "Videos"
}

function baixar_indices {
	contador_indices=1; #contador de página atual
	
	local prox_pag=true; #só pra poder entrar no ciclo pela primeira vez
	
	echo "Vai começar o download do(s) índice(s), e extração de endereços (URL) das mídias...";
	local total_estimado_indices=$(($midias/12));
	if (( $midias%12 > 0))
		then (( total_estimado_indices++ ));
	fi
	
	while [ "$prox_pag" == "true" ] #enquanto tiver próxima página...
	do
		echo -n -e "\r Índices baixados: $contador_indices / $total_estimado_indices";
		prox_pag=$(grep -o ", \"has_next_page\": [a-z]*\}," indice$contador_indices.html | grep -o -e true -e false); #verificando se o índice atual informa haver próximo índice
		
		if [ "$prox_pag" == "true" ] #há próxima página?
		then
			local ult_img_pag=$(grep -o ", \"end_cursor\": \"[0-9]*\"," indice$contador_indices.html | grep -o "[0-9]*"); # extraindo da página atual o código da próxima (é a última imagem da página atual)
			(( contador_indices++ )); #define a próxima (incrementa)
			local saida_wget=$(wget --user-agent=$user_agent --server-response -q --no-cookies -O indice$contador_indices.html https://www.instagram.com/$nome/?max_id=$ult_img_pag 2>&1 | grep -o "Connection: .*" - );
		fi
	done
	if [ $total_estimado_indices == $contador_indices ]
		then
			echo ". ✔";
			return 0;
		else
			if [ "$saida_wget" == "Connection: close" ]
				then echo ". ✗ Conexão fechada pelo Instagram.";
				else echo ". ✗ $saida_wget.";
			fi
			echo "$nome - $(date) - ERRO: nem todos os índices foram baixados ($contador_indices / $total_estimado_indices)." >> ../../historico.txt;
			return 1;
	fi
}

function extrair_todas_fotos {
	local indices_percorridos=1;
	
	while (( $indices_percorridos <= $contador_indices ))
	do
		extrair_foto display_src $indices_percorridos >> ../Fotos.txt;
		local total_fotos=$(wc -l < ../Fotos.txt);
		(( total_fotos-- ));
		echo -n -e "\r Fotos  extraídas: $total_fotos / $midias";
		(( indices_percorridos++ ));
	done
	
	if [ $total_fotos == $midias ]
	then echo ". ✔";
	else echo ". ✗";
	fi
}

function extrair_codes_vídeos {
	local indices_percorridos=1;
	> ../Codigos_Videos.txt; #deletando o conteúdo da lista
	
	local  total_videos=0;
	local  total_videos_old=-1; #pra poder os valores ficarem diferentes e imprimir que tem zero vídeos
	
	while (( $indices_percorridos <= $contador_indices ))
	do #extrair ciclicamente os vídeos, índice-a-índice
	
		#extração de 1 único índice
		{ #MELHORAR: realmente só extrair o vídeo, e não fazer toda essa manipulação de objeto JS
			local videos_indice_atual=$(grep -o '"is_video": true,' indice$indices_percorridos.html | wc -l); #contagem de vídeos no índice atual
	
			if [ $videos_indice_atual -gt 0 ] #sem vídeos no índice, sem extração
			then
				local videos_indice_extraidos=0;
				local campo_processar=1; #cada objeto é um campo  no JSON
		
				while [ $campo_processar -le 12 ]
				do
					local objeto_atual=$(grep -oP '(?<={"code":).*?(?=}, {"code":|}]},)' indice$indices_percorridos.html | cut -d$'\n' -f$campo_processar);
					local is_video=$(echo $objeto_atual | grep -o '"is_video": true' | grep -o true);
			
					if [ "$is_video" == "true" ] #se o objeto atual é um vídeo...
						then echo $objeto_atual | cut -d'"' -f2 >> ../Codigos_Videos.txt;
					fi

					(( campo_processar++ ));
				done
			fi
		}
	
		local total_videos=$(wc -l < ../Codigos_Videos.txt);
		if [ $total_videos -ne $total_videos_old ]
		then #impedir impressão repetitiva dos mesmos totais de vídeos extraídos
			echo -n -e "\r Vídeos extraídos: $total_videos / ?";
			total_videos_old=$total_videos;
		fi
		
		(( indices_percorridos++ ));
	done
	echo ".";
}

function prompt_nome_da_conta {
	clear;
	echo "Instagram Downloader - dev 0.6 (11 de setembro de 2016)";
	linha_horizontal =;
	
	echo -n "Informe o "; setterm -underline on; echo -n "nome"; setterm -underline off; echo    " da conta-alvo. O script baixará todas as mídias dentro de uma pasta.";
	
	echo -n " o nome da conta fica na URL em \"instagram.com/<"; setterm -underline on; echo -n "nome"; setterm -underline off; echo   ">\";";
	echo " as mídias são fotos (JPG) e vídeos (MP4);";
	read -p " Conta-alvo: " nome;
	linha_horizontal -;
}

function verificar_conta_existe {
	wget --delete-after --user-agent=$user_agent --no-cookies -q https://www.instagram.com/$nome/; #baixa o índice 1 e deleta depois
	
	if [ $? -ne 0 ] #testando se o download do índice não deu certo
	then #se não deu certo (retornos 1~8)...
		echo "Parece que a conta não existe! 🙁";
		echo " Resolução de problemas. Faça na ordem:";
		echo "  digitou certo? Verifique, e se digitou errado, tente outra vez;";
		echo "  a conexão com a internet, como vai? Verifique, e corrija se houver problemas;";
		echo "  a conta foi renomeada? Se o nome realmente é este, pode ser que a(o) dona(o) mudou o nome dela, e você precisará buscar pelo novo nome. Se a renomeação foi recente, talvez não apareça (ainda) em resultados de busca fora do Instagram;";
		echo "  a conta foi removida? Se não for possível encontrar o novo nome da conta, mesmo depois de algum tempo, pode ser que a conta tenha sido deletada pelo(a) dono(a). Se a(o) dona(o) não decidir criar outra, é fim da linha, guarde as mídias que você já baixou e busque outras contas interessantes para você.";
		echo;
		echo "Para realizar as buscas acima sugeridas, você deve usar seu navegador de internet, pois o script não lida com isso.";
		echo;
		echo "  Dica: buscar o \"nome de documento\" (e variações) da(o) dona(o) da conta-alvo pode ajudar, pois o Instagram pertence ao Facebook, e o Facebook tem uma \"política de nome real\". Fazer uma busca reversa de imagens pode ajudar também.";
		echo "  Privacidade: caso seja um objetivo seu manter-se anônimo, atente-se para o fato de que, ao buscar, os sites que você usar poderão usar seu navegador para lhe identificar, através de cookies. O script não usa cookies, mas se você é identificado no navegador e depois alguém usa o script para baixar aquela mesma conta que você buscou, pode ser que você seja relacionado ao download.";
		denovo_denovo;
		#despedida;
	else
		echo -n "Conta encontrada! ";  #se deu certo (retorno 0 do wget)...
		return 0;
	fi
}

function data_mais_recente {
	local data_mais_recente=$(echo $(grep -o '"date": [0-9]*,' indice$1.html | grep -o '[0-9]*')| cut -d" " -f1);
	date -d @$data_mais_recente;
}

function confirmar_identidade {
	echo "É esta?";
	
	echo -n " │ Nome  : ";
	echo -e $(grep -o '"full_name": "[^"]*"' indice1.html | cut -d: -f2 | grep -o '".*"' | grep -o '[^"]*');
	
	echo -n " │ Bio   : ";
	local bio=$(grep -o '"biography": "[^"]*"' indice1.html | cut -d: -f2- | cut -d' ' -f2-); # PROBLEMA: bios com aspas ficam quebradas.
	if [ "$bio" == "" ] #pra não dar erro em biografia vazia...
	then echo " ";
	else echo -e $bio;
	fi
		
	echo -n " │ Mídias: ";
	midias=$(grep -o '"media": {"count": [0-9]*,' indice1.html | grep -o '[0-9]*');
	echo -n $midias;
	if (( "$midias" -ne "" ))
	then
		echo -n " (indices:";
		local total_estimado_indices=$(($midias/12));
		if (( $midias%12 > 0))
			then (( total_estimado_indices++ ));
		fi
		echo -n "$total_estimado_indices";
		echo -n ")";
		echo -n "	-	 mais recente: "; data_mais_recente 1;
	else echo;
	fi
	
	read -p " (sim/não): " confirmada;
	case  $confirmada in
	sim|Sim|s|S)
		echo "Identidade confirmada.";
	;;
	não|Não|n|N)
		echo "Identidade negada. Pressione qualquer tecla para rodar o script novamente. CTRL+C para encerrar.";
		cd ..;
		cd ..;
		read;
		main;
	;;
	*)
		echo "Não entendi o que você escreveu. Por favor, escreva apenas \"sim\" ou \"não\".";
		confirmar_identidade;
	;;
	esac
	linha_horizontal -;
}

function extrair_foto_perfil { #extração da foto de perfil: HD se tiver, normal se não tiver HD
	local perfil_hd=$( extrair_foto profile_pic_url_hd 1);
	if [ "$perfil_hd" == "" ]
		then extrair_foto profile_pic_url 1 > ../Fotos.txt;
		else extrair_foto profile_pic_url_hd 1 > ../Fotos.txt;
	fi
}

function verificar_conta_privada {
	local privada=$(grep -o ", \"is_private\": [a-z]*," indice1.html | grep -o -e true -e false); #verificando se a conta é privada ou não
	if [ $privada == 'true' ] #informando ao usuário se dará pra baixar ou não
	then
		echo "Conta privada! 😞 ";
		# LOG : gravar que a conta $nome é privada
		cd ..; #saindo do diretório de índices
		wget --user-agent=$user_agent -nc --no-cookies -q -i Fotos.txt;
		echo "A única coisa que esse script podia fazer, fez: baixar a foto de perfil.";
		echo "Não é possível fazer mais pois contas privadas precisam de login e aprovação para serem visualizadas.";
		echo;
		echo "Que tal você buscar outra conta para baixar as mídias: uma que seja pública?";
		echo "Alternativamente (se você realmente faz questão de ver essa conta), você pode tentar novamente no futuro: quem sabe o/a dono(a) da conta muda de ideia e torna a conta pública?";
		cd ..; #saindo do diretório $nome
		denovo_denovo;
		#despedida;
	else # se a conta não for privada...
		return 0; #prosseguir com o script
	fi
}

function verificar_conta_zerada {
	if [ $midias -eq 0 ]
	then
		echo "Conta zerada!  Sem nenhuma mídia, o script não tem o que fazer.";
		# LOG : gravar que a conta $nome está zerada
		cd ..; #saindo da pasta índices
		cd ..; #saindo da pasta $nome
		denovo_denovo;
	else # se a conta tiver pelo menos 1 foto
		return 0; #prosseguir com o script
	fi
}

function despedida {
	echo;
	echo "✗ Concluído sem sucesso.";
	linha_horizontal -;
	exit 1;
}

function gerencia_diretorio {
	if [ ! -d "$1" ] #testando  se o diretório informado NÃO existe
	then
		mkdir $1; #criando diretório
		cd $1; #entrando no diretório
		return 0;
	else #se o diretório já existia
		cd $1;
		return 1;
	fi
}

function denovo_denovo {
	linha_horizontal -;
	read -p "Pressione qualquer tecla para rodar o script de novo, ou dê CTRL+C para encerrar.";
	main;
}

function verificar_fotos_novas {
	gerencia_diretorio $nome;
	local status_nome=$?; # 0=não existia; 1=existia
# diretório: $nome

	if [ $status_nome -eq 1 ] #se já existia o diretório com o nome da conta
	then
		echo -n "Diretórios: ";
		echo -n "✔ $nome; ";
		
		gerencia_diretorio Indices;
		local status_indices=$?; # 0=não existia; 1=existia
# diretório: Indices
		if [ $status_indices == 1 ] #Se já existia o diretório de índices
		then
			echo -n "✔ Indices. ";
			
			if [ -f indice1.html ] #Se já existia o indice1.html
			then
				echo "Encontrado indice1.html.";
				wget --user-agent=$user_agent --no-cookies -q -O indice1_new.html https://www.instagram.com/$nome/; #baixando o indice1 da conta, silenciosamente
				
				grep -o '"'display_src'": "https://[a-z0-9/\._-]*\.jpg' indice1.html | cut -d'"' -f4 | grep -o "/[0-9_]*_n\.jpg" | cut -d/ -f2 > ../Fotos_old.txt; #corta as URLs das fotos, pegando só os nomes das fotos
				grep -o '"'display_src'": "https://[a-z0-9/\._-]*\.jpg' indice1_new.html | cut -d'"' -f4 | grep -o "/[0-9_]*_n\.jpg" | cut -d/ -f2 > ../Fotos_new.txt; #corta as URLs das fotos, pegando só os nomes das fotos
				
				local cont_indices_iguais=$(diff ../Fotos_old.txt ../Fotos_new.txt | grep -c "> .*"); # só dará alguma saída quando forem diferentes.
				if (( "$cont_indices_iguais" > 0 )) #se não for nulo, os arquivos são diferentes
				then
					echo "✔ Há $cont_indices_iguais fotos novas no indice1.html!";
					{
						echo -n "   Mídia mais recente no servidor: "; data_mais_recente 1_new;
						echo -n "   Mídia mais recente localmente : "; data_mais_recente 1;
					}
					echo "  O script vai seguir a execução normal.";
				else
					echo -n "✗ Não há fotos novas no indice1.html.";
					echo -n " Mídia mais recente: "; data_mais_recente 1;
					echo    "  Sem fotos novas, não tem porquê o script prosseguir.";
					echo    " Se você quiser forçar o download de todos os índices, simplesmente exclua o indice1.html e rode o script de novo";
					echo "  Isso é útil no caso de nem todas as mídias novas terem sido baixadas da última vez.";
					rm -f ../Fotos_old.txt ../Fotos_new.txt indice1_new.html;
					cd ..; # saindo do diretorio Indices
					cd ..; # saindo do diretorio $nome
					echo "$nome - $(date) - nenhuma mídia nova." >> historico.txt;
					denovo_denovo;
				fi
			else
				echo "Não encontrado indice1.html.";
			fi
			
		else
			echo -n "✗ Indices ."; # encerra as verificações e volta pro main, diretório Indices
		fi
	else 					#se não existia o diretório com o nome da conta
		echo "Diretório não.";
		gerencia_diretorio Indices; #se não tem diretório $nome, não tem diretório Indices dentro...
		#encerra as verificações e volta pro main, diretório Indices
	fi
}

function main {
	readonly user_agent="Wget"; #se não puser assim, o script informa detalhes demais, como a versão e onde foi compilado

#um monte de verificações necessárias para prevenir todo tipo de erro
	{
	# diretório: padrão
		if [ ! -f "historico.txt" ] #testando  se já existe LOG
			then echo -n "" > historico.txt;
		fi
		
		prompt_nome_da_conta;   #solicita o nome da conta-alvo para o usuário
		verificar_conta_existe; #se a conta informada não existe, o script encerra-se
	# diretório: $nome, Indices
		verificar_fotos_novas;  #se não tiver fotos novas na conta, o script encerra-se	
		wget --user-agent=$user_agent --no-cookies -q -O indice1.html https://www.instagram.com/$nome/; #baixando o indice1 da conta, silenciosamente
		confirmar_identidade;	
		extrair_foto_perfil;  #se a conta está certa , baixa a foto de perfil
	
		# verificando se as outras fotos são inacessíveis ou inexistentes:
		verificar_conta_privada; #se a conta é privada, o script encerra-se
		verificar_conta_zerada;  #se a conta é zerada , o script encerra-se
	}
#os downloads, propriamente ditos	
	{
		setterm -cursor off;
		baixar_indices;
		extrair_todas_fotos;  #diretamente JPG
		extrair_codes_vídeos; #código (code) apenas... Depois tem que baixar as páginas, extrair url, e baixar
		
		cd ..; #saindo do diretório "Índices", para começar os downloads
	# diretório: $nome
		sleep 3;
	
		baixar_fotos;
		local total_videos=$(wc -l < Codigos_Videos.txt);
		if [ $total_videos -gt 0 ]
			then baixar_videos;
		fi
		linha_horizontal -;
		# LOG : gravar que foram baixados N videos da conta $nome
		
	#diretório: $nome
	}
#uma despedida
	{
		cd ..; # saindo do diretório $nome
		echo "✔ Concluído com sucesso!";
		setterm -cursor on;
		echo "Quando você rodar o script da próxima vez para $nome, somente mídias novas serão baixadas.";
		notify-send "Instagram Downloader: concluído com sucesso.";
		denovo_denovo;
	}
}
main;
