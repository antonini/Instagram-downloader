#!/bin/bash
# Instagram Downloader			# Baixador de Instagram
# created on 2016 by Anders Bateva	# criado em 2016 por Anders Bateva
# https://github.com/andersbateva/Instagram-downloader

function linha_horizontal {
	tput dim;
	printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' $1;
	tput sgr0;
}

function extrair_URL_foto {	grep -o '"'$1'": "https://[a-z0-9/\._-]*\.jpg' $2 | cut -d'"' -f4; } #Curiosidade: terminar o link como .jpg.html faz uma arte ASCII da foto.

function extrair_URL_video { grep -o '"'video_url'": "https://[a-z0-9/\._-]*\.mp4' -- $1 | cut -d'"' -f4; }  # erros por conta de códigos com  "-" acontecem aqui (grep). Não pode ser aspas simples no $1, e aspas duplas são inúteis (mesma coisa que se estivesse sem).

function baixar_fotos {
	linha_horizontal -;
	echo -n " Começando a baixar as imagens";
	tput dim; echo -n " (JPG) "; tput sgr0;
	echo "de $nome...";
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
	
	total_fotos_baixadas=0;
	tput dim; #deixando a barra de progresso à meia-luz
	while read line; do
		local OK=$(wget -nc --user-agent=$user_agent --no-cookies -q --show-progress --progress=bar:noscroll "$line" 2>&1 | grep -o '100%');
		   #silenciosamente, sem sub-diretórios, sem cookie, sem scroll, e sem cobbler
		   
		# Imprressão dos quadradinhos a cada 1, dos espaços a cada 10, e dos "500" a cada 500
		{
			if [ "$OK" == "100%" ]
			then
				if (( $(( total_fotos_baixadas % 500 )) == 0 && $total_fotos_baixadas > 0 )) # informa a cada 500 que deu 500...
				then
					tput sgr0;
					echo -n " 500";
					tput dim;
				fi
				if (( $(( total_fotos_baixadas % 100 )) == 0 && $total_fotos_baixadas > 0 )) # dá quebra de linha de 100 em 100 fotos
					then echo;
				fi
				if  [ $(( total_fotos_baixadas % 10 )) -eq 0 ] # dá espaço de 10 em 10 fotos
					then echo -n " ";
				fi
				echo -n "";
				(( total_fotos_baixadas++ ))
			fi
		}
	done < Fotos.txt #foto de perfil já consta no arquivo
	tput sgr0;
	echo; echo;
	echo "Fotos (novas) baixadas: $total_fotos_baixadas.";
	# LOG : gravar que foram baixadas $total_fotos_baixadas da conta $nome
}

function baixar_videos {
	gerencia_diretorio Videos;
	linha_horizontal -;
	rm -f Paginas_Videos.txt;
	rm -f URLs_Videos.txt;
	
	#acrescentando a URL antes das linhas de "Codigos_Videos.txt", para produzir "Paginas_Videos.txt"
	{
		while read line
		do
    		echo "https://www.instagram.com/p/$line" >> Paginas_Videos.txt;
		done < ../Codigos_Videos.txt #Esses códigos foram extraídos na função "extrair_codes_vídeos"...
	}
	
	#baixando as páginas dos vídeos em si, a partir de "Paginas_Videos.txt"
	{
		local indices_videos_baixados=0;
		while read line; do
			wget -nc --user-agent=$user_agent --no-cookies -q "$line"; #baixa a página do vídeo
			(( indices_videos_baixados++ ));
			dialog --cr-wrap --backtitle "$titulo_fundo"  --title "Baixando páginas de vídeo" --infobox "$indices_videos_baixados" 0 0;
		done < Paginas_Videos.txt
		echo;
	}
	
	#extraindo as URLs das páginas dos vídeos
	{
		while read line
		do
	    	extrair_URL_video $line >> URLs_Videos.txt; # erros por conta de códigos com  "-" acontecem aqui (grep).
		done < ../Codigos_Videos.txt #As páginas baixadas têm por nome os códigos!
	}
	
	#baixando os vídeos, finalmente, a partir de "URLs_Videos.txt"
	{
		local videos_baixados=0;
		while read line; do
			dialog --cr-wrap --backtitle "$titulo_fundo"  --title "Baixando vídeos" --infobox "$videos_baixados" 0 0;
			nome_video=$(echo $line | rev | cut -d'/' -f 1 | rev); #extraindo o nome do vídeo a partir da URL...
			if [ ! -f "$nome_video" ] #testando se o vídeo já foi baixado
				then
					tput dim; #PROBLEMA: wget não aceita ficar em tom mais claro!
					wget -nc --user-agent=$user_agent --no-cookies -q --show-progress --progress=bar:noscroll "$line";
					tput sgr0;
					# Nota: barra de progresso são boas para os vídeos. Eles são umas 20x maiores que as fotos (download demorado).
					if (( "$?" == "0" ))
						then tput cuu1; tput el; #sobe uma linha e apaga o conteúdo dela - barra de progresso.
						else echo "Erro no download do vídeo $videos_baixados";
					fi
			fi
			tput cuu1; tput el; #sobe uma linha e apaga o conteúdo dela - "vídeo baixados...".
			(( videos_baixados++ ));
		done < URLs_Videos.txt
		dialog --cr-wrap --backtitle "$titulo_fundo"  --title "Baixando vídeos" --infobox "$videos_baixados" 0 0;
	}
	
	cd ..; #Saindo da pasta "Videos"
}

function baixar_indices {
	local total_estimado_indices=$(estimativa_total_indices);
	contador_indices=1;
	
	if [ -f ../Fotos.txt ] # Se essa conta já foi baixada anteriormente, extrair os nomes das fotos.
	then
		grep -o 'https://[a-z0-9/\._-]*\.jpg' ../Fotos.txt | grep -o "/[0-9_]*_n\.jpg" | cut -d/ -f2 > ../Fotos_old.txt; # Na lista de URLS de fotos velhas (Fotos.txt), corta só os nomes e salva em "Fotos_old.txt".
	fi
	
	while [ "$contador_indices" -le "$total_estimado_indices" ] # Parar ao chegar ao total estimado de índices
	do	
		# Baixando cada índice, e verificando quantas fotos novas há
		{
			wget --user-agent=$user_agent -q --no-cookies -O indice$contador_indices.html https://www.instagram.com/$nome/?max_id=$ult_img_pag; # Baixando o índice (novo)
			pegar_nome_foto "$contador_indices" > ../Fotos_new.txt; # Extraindo os nomes das fotos no índice novo
			
			# Checando o total de fotos novas no índice novo, para comparar com as fotos antigas.
			{
				
				if [ -f ../Fotos.txt ] && [ -f ../Fotos_new.txt ]
				then
					# QUE TAL CONTAR QUANTAS LINHAS TINHA?
					local cont_fotos_diferentes=$(diff ../Fotos_old.txt ../Fotos_new.txt | grep -c "> .*"); # Testa quantas linhas diferentes há em "Fotos_new.txt", comparado com "Foto_old.txt", e atribui à $conta_fotos_iguais.
					if [ "$cont_fotos_diferentes" -eq 0 ]
						then break;
					fi
				fi
			}
			dialog --cr-wrap --backtitle "$titulo_fundo"  --title "Baixando índices" --infobox "$contador_indices / $total_estimado_indices
Índice $contador_indices: fotos novas = $cont_fotos_diferentes." 0 0;
			# INFORMAR QUE, SE O TOTAL DE FOTOS NOVAS É MENOR QUE 12, OS PRÓXIMOS ÍNDICES NÃO SERÃO BAIXADOS?
		}
		
		# Verificando se tem próxima página, e . Se não tiver, encerra o loop "while".
		{
			local prox_pag=$(grep -o ", \"has_next_page\": [a-z]*\}," indice$contador_indices.html | grep -o -e true -e false); #extração do "true" ou "false" sobre haver próxima página
			if [ "$prox_pag" == "true" ] #há próxima página?
			then
				local ult_img_pag=$(grep -o ", \"end_cursor\": \"[0-9]*\"," indice$contador_indices.html | grep -o "[0-9]*"); # extraindo da página atual o código da próxima (é a última imagem da página atual)
				(( contador_indices++ )); #define a próxima (incrementa)
			else
				dialog --cr-wrap --backtitle "$titulo_fundo"  --title "Baixando índices" --infobox "$contador_indices / $total_estimado_indices" 0 0;
				break; #sem próxima página, encerra os downloads
			fi
		}
	done
}

function extrair_URL_todas_fotos {
	local indices_percorridos=1;
	
	while (( $indices_percorridos <= $contador_indices ))
	do
		extrair_URL_foto display_src "indice$indices_percorridos.html" >> ../Fotos.txt;
		local total_fotos=$(wc -l < ../Fotos.txt);
		(( total_fotos-- ));
		
		dialog --cr-wrap --backtitle "$titulo_fundo"  --title "Extraindo fotos" --infobox "$total_fotos / $midias" 0 0;
		
		(( indices_percorridos++ ));
	done
	dialog --cr-wrap --backtitle "$titulo_fundo"  --title "Extraindo fotos" --infobox "$total_fotos / $midias" 0 0;
}

function pegar_nome_foto { #$1 = numero do indice
	grep -o '"'display_src'": "https://[a-z0-9/\._-]*\.jpg' indice$1.html | cut -d'"' -f4 | grep -o "/[0-9_]*_n\.jpg" | cut -d/ -f2; #corta as URLs das fotos, pegando só os nomes das fotos
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
		
		# Informando o usuário
		{
			local total_videos=$(wc -l < ../Codigos_Videos.txt);
			if [ $total_videos -ne $total_videos_old ]
			then #impedir impressão repetitiva dos mesmos totais de vídeos extraídos
				dialog --cr-wrap --backtitle "$titulo_fundo"  --title "Extraindo vídeos" --infobox "$total_videos / ?" 0 0;
				total_videos_old=$total_videos;
			fi
		}
		
		(( indices_percorridos++ ));
	done
	dialog --cr-wrap --backtitle "$titulo_fundo"  --title "Extraindo vídeos" --infobox "$total_videos / ?" 0 0;
}

function verificar_conta_existe {
	wget --user-agent=$user_agent --no-cookies -q -O indice1_new.html https://www.instagram.com/$nome/; #baixa o índice 1_new
	
	if [ $? -ne 0 ] #testando se o download do índice não deu certo
	then #se não deu certo (retornos 1~8)...
		dialog --cr-wrap --backtitle "$titulo_fundo"  --ok-label "Rodar novamente" --title "Parece que a conta não existe! 🙁 " --msgbox "Resolução de problemas. Faça na ordem:
  digitou certo? Verifique, e se digitou errado, tente outra vez;
  a conexão com a internet, como vai? Verifique, e corrija se houver problemas;
  há espaço no dispositivo de armazenamento? Se o script não conseguir baixar o índice, vai considerar que a conta não existe
  a conta foi renomeada? Se o nome realmente é este, pode ser que a(o) dona(o) mudou o nome dela, e você precisará buscar pelo novo nome. Se a renomeação foi recente, talvez não apareça (ainda) em resultados de busca fora do Instagram;
  a conta foi removida? Se não for possível encontrar o novo nome da conta, mesmo depois de algum tempo, pode ser que a conta tenha sido deletada pelo(a) dono(a). Se a(o) dona(o) não decidir criar outra, é fim da linha, guarde as mídias que você já baixou e busque outras contas interessantes para você.
 
Para realizar as buscas acima sugeridas, você deve usar seu navegador de internet, pois o script não lida com isso.
  Dica: buscar o \"nome de documento\" (e variações) da(o) dona(o) da conta-alvo pode ajudar, pois o Instagram pertence ao Facebook, e o Facebook tem uma \"política de nome real\". Fazer uma busca reversa de imagens pode ajudar também.
  Privacidade: caso seja um objetivo seu manter-se anônimo, atente-se para o fato de que, ao buscar, os sites que você usar poderão usar seu navegador para lhe identificar, através de cookies. O script não usa cookies, mas se você é identificado no navegador e depois alguém usa o script para baixar aquela mesma conta que você buscou, pode ser que você seja relacionado ao download.
		" 0 0;
		
		cd ..; #sai do diretorio indices
		cd ..; #sai do diretorio $nome
		rm -r -f $nome;
		main;
	else return 0;
	fi
}

function data_mais_recente {
	local data_mais_recente=$(echo $(grep -o '"date": [0-9]*,' indice$1.html | grep -o '[0-9]*')| cut -d" " -f1);
	date -d @$data_mais_recente "+%d/%b/%Y %I:%H %Z";
}

function confirmar_identidade { #$1 = nome do indice
	local bio=$(grep -o '"biography": "[^"]*"' $1 | cut -d: -f2- | cut -d' ' -f2-);
	if [ "$bio" == "" ] #pra não dar erro em biografia vazia...
		then bio=" ";
	fi
	
	midias=$(grep -o '"media": {"count": [0-9]*,' $1 | grep -o '[0-9]*');
	if (( "$midias" -ne "" ))
	then
		local total_estimado_indices=$(($midias/12));
		if (( $midias%12 > 0))
			then (( total_estimado_indices++ ));
		fi
		local midia_mais_recente=$(data_mais_recente "1_new");
	else midia_mais_recente=" ";
	fi
	
	dialog --cr-wrap --backtitle "$titulo_fundo" --title "Confirmação de identidade" --ok-label "Sim" --cancel-label "Não" --yesno "É esta?
Nome  : $(grep -o '"full_name": "[^"]*"' $1 | cut -d: -f2 | grep -o '".*"' | grep -o '[^"]*')
Bio  : $bio
Mídias: $midias (índices: $total_estimado_indices)
        - mais recente: $midia_mais_recente" 0 0;
	local resposta=$?;
	if [ "$resposta" == 1 ] # Caso o usuário tenha negado, o script roda novamente
		then
			cd ..; cd ..; #sai dos diretorios "Índices" e $nome
			rm -r -f $nome;
			main;
	fi
	
	verificar_conta_privada "indice1_new.html";
}

function extrair_URL_foto_perfil { #extração da foto de perfil: HD se tiver, normal se não tiver HD
	local perfil_hd=$( extrair_URL_foto profile_pic_url_hd $1);
	if [ "$perfil_hd" == "" ]
		then extrair_URL_foto profile_pic_url $1 > ../Fotos.txt;
		else extrair_URL_foto profile_pic_url_hd $1 > ../Fotos.txt;
	fi
}

function verificar_conta_privada { #$1 = nome do indice
	local privada=$(grep -o ", \"is_private\": [a-z]*," $1 | grep -o -e true -e false); #verificando se a conta é privada ou não
	if [ $privada == 'true' ] #informando ao usuário se dará pra baixar mídias ou não
	then
		extrair_URL_foto_perfil "indice1_new.html";
		cd ..; #saindo do diretório de índices
		wget --user-agent=$user_agent -nc --no-cookies -q -i Fotos.txt;
		sleep 1;
		# LOG : gravar que a conta $nome é privada
		dialog --cr-wrap --backtitle "$titulo_fundo"  --ok-label "Rodar novamente" --title "Conta privada! 😞 " --msgbox "A única coisa que esse script podia fazer, fez: baixar a foto de perfil.
Não é possível fazer mais pois contas privadas precisam de login e aprovação para serem visualizadas.

Que tal você buscar outra conta para baixar as mídias: uma que seja pública?
Alternativamente (se você realmente faz questão de ver essa conta), você pode tentar novamente no futuro: quem sabe o/a dono(a) da conta muda de ideia e torna a conta pública?" 0 0;

		cd ..; #saindo do diretório $nome
		main;
	else return 0; # se a conta não for privada, prosseguir com o script
	fi
}

function verificar_conta_zerada {
	if [ $midias -eq 0 ]
	then
		dialog --cr-wrap --backtitle "$titulo_fundo"  --ok-label "Rodar novamente" --title "Conta zerada!  " --msgbox "Sem nenhuma mídia, o script não tem o que fazer." 0 0;
		# LOG : gravar que a conta $nome está zerada
		cd ..; #saindo da pasta índices
		cd ..; #saindo da pasta $nome
		main;
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

function verificar_fotos_novas { # $1 = número do índice
	if [ -f indice$1.html ] #Se já existia o indice$1.html
		then
			grep -o '"'display_src'": "https://[a-z0-9/\._-]*\.jpg' indice$1.html | cut -d'"' -f4 | grep -o "/[0-9_]*_n\.jpg" | cut -d/ -f2 > ../Fotos_old.txt; #corta as URLs das fotos, pegando só os nomes das fotos
			grep -o '"'display_src'": "https://[a-z0-9/\._-]*\.jpg' indice$1_new.html | cut -d'"' -f4 | grep -o "/[0-9_]*_n\.jpg" | cut -d/ -f2 > ../Fotos_new.txt; #corta as URLs das fotos, pegando só os nomes das fotos
			
			local cont_indices_iguais=$(diff ../Fotos_old.txt ../Fotos_new.txt | grep -c "> .*"); # só dará alguma saída quando forem diferentes.
			if (( "$cont_indices_iguais" > 0 )) #se não for nulo, os arquivos são diferentes
			then
				dialog --cr-wrap --backtitle "$titulo_fundo"  --title "Verificação de fotos novas no índice 1" --infobox "✔ Há $cont_indices_iguais (de 12) fotos novas no indice$1.html!
Mídia mais recente
  no servidor: $(data_mais_recente 1_new)
  localmente : $(data_mais_recente 1)" 0 0;
				   
			else
				dialog --cr-wrap --backtitle "$titulo_fundo"  --ok-label "Rodar novamente" --title "Verificação de fotos novas no índice 1" --msgbox "✗ Não há fotos novas no indice$1.html.
 Mídia mais recente: $(data_mais_recente 1)
 Sem fotos novas, não tem porquê o script prosseguir.
  Se você quiser forçar o download de todos os índices, simplesmente exclua o indice$1.html e rode o script de novo
  Isso é útil no caso de nem todas as mídias novas terem sido baixadas da última vez. 
  (Mas não obrigatório. Da próxima vez que houver foto nova, o script executará normalmente mesmo)" 0 0;
				
				rm -f ../Fotos_old.txt ../Fotos_new.txt indice1_new.html;
				cd ..; # saindo do diretorio Indices
				cd ..; # saindo do diretorio $nome
				echo "$nome - $(date) - nenhuma mídia nova." >> historico.txt;
				main;
			fi
	else #else do índice1.html
		echo "Não encontrado indice$1.html localmente.";
	fi #fi do índice1.html
}

function estimativa_total_indices {
	local total_estimado_indices=$(($midias/12));
	if (( $midias%12 > 0))
		then (( total_estimado_indices++ ));
	fi
	echo $total_estimado_indices;
}

function main {
	clear; tput sgr0;
	
	readonly user_agent="Wget" 2>&1; # Definindo o nome do script que será informado para os servidores do Instagram. No caso, é o próprio nome do comando de download, sem nenhum detalhe adicional que ele daria por padrão. O "2>&1" é um macete para evitar a impressão desnecessária de "linha xxx: user_agent: a variável permite somente leitura".

	if [ ! -f "historico.txt" ] #testando  se já existe LOG
		then echo -n "" > historico.txt;
	fi
	
	nome=$(dialog --backtitle "Instagram Downloader - dev 0.7 (01 de janeiro de 2017)" --title "NOME" --inputbox "Informe o nome da conta-alvo. O script baixará todas as fotos e vídeos dentro de pastas." --stdout 0 0); #solicita o nome da conta-alvo para o usuário #não baixa indices
	local resposta=$?;
	if [ "$resposta" == 1 ] # CANCELAR = encerrar script
		then
			clear; exit;
	fi
	
	titulo_fundo="Instagram Downloader - conta: $nome";
	
	gerencia_diretorio "$nome";
	gerencia_diretorio "Indices";

#um monte de verificações necessárias para prevenir todo tipo de erro
	{	
		verificar_conta_existe; 					#baixa o indice1_new.html, se a conta existir, se não, erro.
		confirmar_identidade    "indice1_new.html"; #não baixa indices, só checa o informado. Se não tiver, sai de "índices" e $nome. Gera $midias;
		#verificar_conta_privada "indice1_new.html"; #não baixa indices, só checa o informado. Se não tiver, sai de "índices" e $nome.
		verificar_conta_zerada;  					#não baixa indices, só checa $midias (gerado em confirmar_identidade). Se não tiver, sai de "ìndices" e $nome.
		verificar_fotos_novas "1"; 					#não baixa indices.
		sleep 2;
	}
	
#os downloads, propriamente ditos	
	{
		baixar_indices;
		extrair_URL_foto_perfil "indice1.html";  #se a conta está certa , baixa a foto de perfil #não baixa indices
		extrair_URL_todas_fotos;  #extrai diretamente a URL do JPG.
		extrair_codes_vídeos; #código (code) apenas... Depois tem que baixar as páginas, extrair url, e baixar
		
		cd ..; #saindo do diretório "Índices", para começar os downloads
	# diretório: $nome
		sleep 3;
		clear;
		
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
		notify-send "Instagram Downloader: concluído com sucesso.";
		dialog --cr-wrap --backtitle "$titulo_fundo"  --ok-label "Rodar novamente" --title "✔ Concluído com sucesso!" --msgbox "Baixadas $total_fotos_baixadas fotos novas.

Quando você rodar o script da próxima vez para $nome, somente mídias novas serão baixadas." 0 0;
		main;
	}
	
}
main;
