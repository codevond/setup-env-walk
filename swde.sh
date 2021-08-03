#!/usr/bin/env bash
# feel free to contact zengw@theteam247.com

project_name='walks-apis'
project_parent_folder="/home/${USER}"
script_folder="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
git_folder="${project_parent_folder}/${project_name}"
laradock_folder="${git_folder}/laradock"
frontend_folder="/home/${USER}/walks_frontend"
branch='zengw'

echo '----------------- folders -----------------'
echo 'proejct_parent_folder is : '$project_parent_folder
echo 'script_fodler is:' $script_folder
echo 'git_folder is:' $git_folder
echo 'laradock_folder is:' $laradock_folder
echo '-------------end folders--------------------'

function show_help() {
	echo 'Set Walks Develop Environment'
	echo "feel free to contact zengw@theteam247.com"
	echo 'this script will set up takewalk develop environment using docker-apis'
	echo ''
	echo "${git_folder}, You would find api codes and docker configuration there"
	echo "${frontend_folder}, You would find vue codes there"
	echo ''
	echo 'Steps you should follow'
	echo '1. Make sure public key in github, private key in ec2, refer: https://docs.github.com/en/github/authenticating-to-github/connecting-to-github-with-ssh'
	echo '2. Set git username and email'
	echo "    git config --global user.name 'Your name'" 
	echo "    git config --global user.email 'Your email'" 
	echo "3. Run script (do not use root account): ${script_folder}/swde.sh launch" 
	echo "4. Edit host file both in your local computer and ec2" 
}


# docker docker-compose mysql-client nodejs python
function install_softwares() {
	sudo apt update -y
	curl -sL https://deb.nodesource.com/setup_14.x | sudo -E bash -
	sudo apt-get install docker-ce docker-ce-cli containerd.io mysql-client nodejs python -y
	sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
	sudo chmod +x /usr/local/bin/docker-compose
}


# start laradock containers
function init_project() {
	echo 'step 0: install softwares'
	install_softwares

	echo 'step 0 done'

	echo 'step 1: clone docker-apis'

	cd $project_parent_folder

	git clone git@github.com:takewalks/docker-apis.git --recursive --branch ${branch} ${project_name}

	if [ -d ${git_folder} ];then
		echo 'clone docker-apis ok'
	else
		echo 'clone docker-apis fail, please make sure you have permission'
		exit 1
	fi

	echo 'step 2: copy ssl files'
	cp ${script_folder}/ssl/* ${laradock_folder}/nginx/ssl/
	echo 'done'

	echo 'step 3: make docker-compse .env file'
	cp ${laradock_folder}/.env.docker-walks ${laradock_folder}/.env
	echo 'done'

	echo 'step 4 install docker compose containers, this will take very long time, be patient....'
	cd ${laradock_folder}
	sudo docker-compose down 
	sudo docker-compose up -d nginx mysql redis workspace
	echo 'step 4 done'
}

# php code
function update_php_code() {
	cd $laradock_folder

	function copy_env() {
		env_copy_from=""
		if   [ -f $1/.env.docker-walks ]; then
			env_copy_from=$1/.env.docker-walks 
		elif [ -f $1/local-walks.env ]; then
			env_copy_from=$1/local-walks.env
		elif [ -f $1/.env-local-walks ]; then
			env_copy_from=$1/.env-local-walks
		fi

		if [ $env_copy_from ]; then 
			echo "cp $env_copy_from $1/.env"
			cp $env_copy_from   $1/.env
		fi
		echo 'done'
	}

	function checkout_staging() {
		if [ $1 == 'admin.walks.org' ]; then
			echo "checkout $1 to branch richard-local-test"
			echo "docker-compose exec --user=laradock --workdir=/var/www/$1 workspace git checkout richard-local-test"
			sudo docker-compose exec --user=laradock --workdir=/var/www/$1 workspace git checkout  richard-local-test

		else
			echo "checkout $1 to branch staging"
			echo "docker-compose exec --user=laradock --workdir=/var/www/$1 workspace git checkout staging"
			sudo docker-compose exec --user=laradock --workdir=/var/www/$1 workspace git checkout staging
		fi
	}

	function composer_update() {
		if [ $2 == 'admin.walks.org' ]; then
			echo "cp ${script_folder}/files/admin/* ${git_folder}/$2/app/Config/"
			cp ${script_folder}/files/admin/* ${git_folder}/$2/app/Config/
		fi

		if [ $2 == 'inventoryapi.walks.org' ]; then
			echo "cp ${script_folder}/files/inventory/* ${git_folder}/$2"
			cp ${script_folder}/files/inventory/* ${git_folder}/$2
		fi

		if [ $2 == 'feedbackapi.walks.org' ]; then
			echo "cp ${script_folder}/files/feedback/* ${git_folder}/$2"
			cp ${script_folder}/files/feedback/* ${git_folder}/$2
		fi

		if [ -f $1 ]; then
			echo "docker-compose exec --user=laradock --workdir=/var/www/$2 workspace composer install"
			sudo docker-compose exec --user=laradock --workdir=/var/www/$2 workspace composer install
		fi
	}

	for dir in `ls $git_folder`; do
		if [ -d ${git_folder}/${dir} ] && [[ $dir == *".org" ]];then
			copy_env "${git_folder}/$dir"
			checkout_staging $dir
			composer_update "${git_folder}/$dir/composer.json" $dir
		fi
	done
}

# vue code
function install_frontend_code() {
	mkdir $frontend_folder

	cd $frontend_folder
	echo `pwd`
	git clone git@github.com:takewalks/TakeWalks-FrontEnd.git
	cd TakeWalks-FrontEnd
	git checkout staging
	cp ${script_folder}/files/walk.config.dev.js ${frontend_folder}/TakeWalks-FrontEnd/config/webpack.config.dev.js
	cp ${script_folder}/files/takewalks.env ${frontend_folder}/TakeWalks-FrontEnd/.env
	
	echo "cp ${script_folder}/files/walk.config.dev.js ${frontend_folder}/TakeWalks-FrontEnd/config/webpack.config.dev.js"
	echo "cp ${script_folder}/files/takewalks.env ${frontend_folder}/TakeWalks-FrontEnd/.env"
	npm install --unsafe-perm

	cd $frontend_folder
	echo `pwd`
	git clone git@github.com:takewalks/WalksofItaly-FrontEnd-Nuxt.git
	cd WalksofItaly-FrontEnd-Nuxt
	git checkout staging
	cp ${script_folder}/files/woi.config.js ${frontend_folder}/WalksofItaly-FrontEnd-Nuxt/nuxt.config.js
	cp ${script_folder}/files/woi.env ${frontend_folder}/WalksofItaly-FrontEnd-Nuxt/staging.env

	echo "cp ${script_folder}/files/woi.config.js ${frontend_folder}/WalksofItaly-FrontEnd-Nuxt/nuxt.config.js"
	echo "cp ${script_folder}/files/woi.env ${frontend_folder}/WalksofItaly-FrontEnd-Nuxt/staging.env"
	npm install --unsafe-perm
}

function seed_database() {
	sql_gz="${script_folder}/files/woi_prod.sql.gz"
	if [ ! -f $sql_gz ];then
		echo "${sql_gz} not found"
		exit 1;	
	fi
	echo "gzip -dkf $sql_gz"
	gzip -dkf $sql_gz

	cat ${script_folder}/files/init.sql | mysql -uroot -proot -h 127.0.0.1
	echo 'seed woi_prod.sql... long long time, about 10 min'
 	cat ${script_folder}/files/woi_prod.sql | mysql -uroot -proot -h 127.0.0.1 woi_prod
}

function how_to_config_your_local_host() {
	echo '------------------------------------------------------'
	echo 'edit host file in your local computer and aws ec2'
	echo ''
	for dir in `ls $git_folder`; do
		if [ -d ${git_folder}/${dir} ] && [[ $dir == *".org" ]];then
			echo 'aws.public.ip.address'   "local-${dir}"
		fi
	done
}

function clean_old_files() {
	echo $git_folder
	if [ -d $git_folder ]; then
		read -p "script will delete $git_folder $frontend_folder ,  then remake it, Are you sure [Y/n] ?" -n 1 -r
		echo    # (optional) move to a new line
		if [ $REPLY == 'Y' ]; then
			rm -rf $git_folder
			rm -rf $walks_frontend
		else
			exit 1
		fi
	fi
}


if [ "$1" == "-h" ]; then
	show_help
elif [ "$1" == 'launch' ]; then
	if [ "$USER" == 'root' ]; then
		echo 'do not use root'
		exit 1 
	fi
	clean_old_files
	init_project
	update_php_code
	seed_database
	install_frontend_code
	how_to_config_your_local_host
else
	show_help
fi
