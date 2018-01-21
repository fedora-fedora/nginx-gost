node ("swarm") {
	stage("Clear Work Space") {
		try {
			deleteDir()
		} catch(err) {
			throw err
		}
	}

    withEnv([
		"nginx_gost_git_url=https://git.sdsys.ru/iru/nginx-gost.git",
        "jenkins_ssh_key=/run/secrets/provision-ssh-key",
        "docker_image=nginx-gost",
        "container_name=cprocsp6",
        "docker_registry=dev-registry.infoclinica.ru:5000",
		"cluster_name=dev-iru-swarm",
		"domain_name=infoclinica.lan",
		"mailfrom=jenkins.dev@sdsys.ru",
		"mailto=tomishinets.v@sdsys.ru",
		"swarm_git_mail=jenkins.dev@sdsys.ru",
        "swarm_git_user=provision",
		"swarm_git_url=ssh://git@git.sdsys.ru:8022/sdsys/swarm.git",
		
    ]) {
		stage("Pull") {
			try {
				git url: "${nginx_gost_git_url}"
			} catch(err) {
				currentBuild.result = "FAILURE"
                String error = "${err}";
				mail charset: 'UTF-8',
					from: "${mailfrom}",
					mimeType: 'text/html',
					subject: "Ошибка Jenkins CI/CD: Имя проекта -> ${env.JOB_NAME}",
					to: "${mailto}",
					body: "<b>Внимание!!!</b> <b><br>\n\nСообщение об ошибке:</b> ${error}  Pull nginx-gost failed\n\n <b><br>Project Name:</b> ${env.JOB_NAME} <b><br>\nBuild Number:</b> ${env.BUILD_NUMBER} <b><br>\nStage Name:</b> Pull <b><br>\nURL Build:</b> ${env.BUILD_URL}"
                deleteDir()
                throw err
			}
		}
        stage("Build") {
            try {
                sh ('''ansible-playbook -e target_dir=${WORKSPACE} ${WORKSPACE}/ansible/generate.configs.yml
				    if [ $? -eq 1 ]; then echo "Can not play ansible playbook"; exit 1; fi
					docker build -t ${docker_registry}/${docker_image}:${BUILD_NUMBER} ${WORKSPACE}/
					if [ $? -eq 1 ]; then echo "Can not build a  ${docker_registry}/${docker_image}:${BUILD_NUMBER}"; exit 1; fi
				''')
            } catch(err) {
				currentBuild.result = "FAILURE"
                String error = "${err}";
				mail charset: 'UTF-8',
					from: "${mailfrom}",
					mimeType: 'text/html',
					subject: "Ошибка Jenkins CI/CD: Имя проекта -> ${env.JOB_NAME}",
					to: "${mailto}",
					body: "<b>Внимание!!!</b> <b><br>\n\nСообщение об ошибке:</b> ${error}\n\n <b><br>Project Name:</b> ${env.JOB_NAME} <b><br>\nBuild Number:</b> ${env.BUILD_NUMBER} <b><br>\nStage Name:</b> Build <b><br>\nURL Build:</b> ${env.BUILD_URL}"
                deleteDir()
                throw err
            } 
        } 
    
        stage("Staging") {
            try {
                sh ('''docker run --name ${container_name} --privileged \
				--security-opt seccomp=unconfined --tmpfs /run --tmpfs /run/lock -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
				--restart always -d -e "ADMIN_LAB=dev-admin-lab.infoclinica.lan" -e "ADMIN_WEB=dev-admin-web.infoclinica.lan" \
				-e "NODE_LAB=node-lab.infoclinica.lan" -e "NODE_WEB=node-web.infoclinica.lan" ${docker_registry}/${docker_image}:${BUILD_NUMBER}
				    sleep 60s
                    status=`docker inspect ${container_name} --format='{{.State.Health.Status}}'`
                    if [ $status != "healthy" ]; then 
                      	echo "Container is not in HEALTHLY"
                      	docker stop ${container_name} && docker rm -f ${container_name}
                      	exit 1
                    else
                        docker stop ${container_name} && docker rm -f ${container_name}
                    fi
                ''')
            } catch(err) {
				currentBuild.result = "FAILURE"
                String error = "${err}";
				mail charset: 'UTF-8',
					from: "${mailfrom}",
					mimeType: 'text/html',
					subject: "Ошибка Jenkins CI/CD: Имя проекта -> ${env.JOB_NAME}",
					to: "${mailto}",
					body: "<b>Внимание!!!</b> <b><br>\n\nСообщение об ошибке:</b> ${error}\n\n <b><br>Project Name:</b> ${env.JOB_NAME} <b><br>\nBuild Number:</b> ${env.BUILD_NUMBER} <b><br>\nStage Name:</b> Staging <b><br>\nURL Build:</b> ${env.BUILD_URL}"
                deleteDir()
				sh 'docker rmi -f ${docker_registry}/${docker_image}:${BUILD_NUMBER}'
				throw err
            } finally {
                sh ('''docker stop ${container_name}
                ''')
                
            }
		}
        stage("Publish") {
			try {
				sh ('''docker push ${docker_registry}/${docker_image}:${BUILD_NUMBER}
				if [ $? -eq 1 ]; then echo "Can not push a  ${docker_registry}/${docker_image}:${BUILD_NUMBER}"; exit 1; fi
				''')
			} catch (err) {
			    currentBuild.result = "FAILURE"
                String error = "${err}";
				mail charset: 'UTF-8',
					from: "${mailfrom}",
					mimeType: 'text/html',
					subject: "Ошибка Jenkins CI/CD: Имя проекта -> ${env.JOB_NAME}",
					to: "${mailto}",
					body: "<b>Внимание!!!</b> <b><br>\n\nСообщение об ошибке:</b> ${error}\n\n <b><br>Project Name:</b> ${env.JOB_NAME} <b><br>\nBuild Number:</b> ${env.BUILD_NUMBER} <b><br>\nStage Name:</b> Publish <b><br>\nURL Build:</b> ${env.BUILD_URL}"
				deleteDir()
				throw err
			}	
        }
    
        stage("Prod-like") {
			try {
				sh (''' ping -c 2 ${cluster_name}1.${domain_name}
				if [ $? -eq 0 ]; then
					export DOCKER_CERT_PATH=/run/secrets/${cluster_name}
					export DOCKER_HOST=tcp://${cluster_name}1.${domain_name}:2376 DOCKER_TLS_VERIFY=1
					docker node ls --format "{{.Hostname}} {{.TLSStatus}}" | while read host status
					do
						if [ $status != Ready ]; then echo "Cluster ${cluster_name}.${domain_name} state is inconsistent"; exit 1
						else echo "HOST: $host STATUS: $status"
						fi
					done
				else echo "Host not Found"; exit 1
				fi
				''')
			} catch(err) {
				currentBuild.result = "FAILURE"
				String error = "${err}";
						
				mail charset: 'UTF-8',
					from: "${mailfrom}",
					mimeType: 'text/html',
					subject: "Ошибка Jenkins CI/CD: Имя проекта -> ${env.JOB_NAME}",
					to: "${mailto}",
					body: "<b>Внимание!!!</b> <b><br>\n\nСообщение об ошибке:</b> ${error}\n\n <b><br>Project Name:</b> ${env.JOB_NAME} <b><br>\nBuild Number:</b> ${env.BUILD_NUMBER} <b><br>\nStage Name:</b> Prod-like <b><br>\nURL Build:</b> ${env.BUILD_URL}"
				deleteDir()
				throw err
				}	
			try {
				sh ('''export DOCKER_CERT_PATH=/run/secrets/${cluster_name}
					export DOCKER_HOST=tcp://${cluster_name}1.${domain_name}:2376 DOCKER_TLS_VERIFY=1
					current_image=`docker inspect ${container_name} --format='{{.Config.Image}}'`
					docker node ls --format "{{.Hostname}}" | while read host
					do
						export DOCKER_HOST=tcp://${host}:2376 DOCKER_TLS_VERIFY=1
						docker stop ${container_name} && sleep 60 && docker rm -f ${container_name}
						docker run -p 443:443 -p 80:80 --name cprocsp6 --privileged --security-opt seccomp=unconfined \
						--tmpfs /run --tmpfs /run/lock -v /sys/fs/cgroup:/sys/fs/cgroup:ro --network=proxy --restart always \
						-d -e "ADMIN_LAB=dev-admin-lab.infoclinica.lan" -e "ADMIN_WEB=dev-admin-web.infoclinica.lan" \
						-e "NODE_LAB=node-lab.infoclinica.lan" -e "NODE_WEB=node-web.infoclinica.lan" ${docker_registry}/${docker_image}:${BUILD_NUMBER}
						docker exec ${container_name} /bin/sh -c 'while read ip host; do curl -f ${host};done < /tmp/iru-hosts'
						if [ $? -eq 1 ]; then
							export DOCKER_HOST=tcp://${cluster_name}1.${domain_name}:2376 DOCKER_TLS_VERIFY=1 
							docker node ls --format "{{.Hostname}}" | while read host1
							do
								export DOCKER_HOST=tcp://${host1}:2376 DOCKER_TLS_VERIFY=1
								some_image=`docker inspect ${container_name} --format='{{.Config.Image}}'`
								if [ ${some_image} != ${current_image} ]; then
									docker stop ${container_name} && sleep 60 && docker rm -f ${container_name}
									docker run -p 443:443 -p 80:80 --name cprocsp6 --privileged --security-opt seccomp=unconfined \
									--tmpfs /run --tmpfs /run/lock -v /sys/fs/cgroup:/sys/fs/cgroup:ro --network=proxy --restart always \
									-d -e "ADMIN_LAB=dev-admin-lab.infoclinica.lan" -e "ADMIN_WEB=dev-admin-web.infoclinica.lan" \
									-e "NODE_LAB=node-lab.infoclinica.lan" -e "NODE_WEB=node-web.infoclinica.lan" ${current_image}
									echo "Return old image and exit"
									exit 1
								fi
							done
						fi
					done
					
				''') 
			} catch(err) {
				currentBuild.result = "FAILURE"
				String error = "${err}";
						
				mail charset: 'UTF-8',
					from: "${mailfrom}",
					mimeType: 'text/html',
					subject: "Ошибка Jenkins CI/CD: Имя проекта -> ${env.JOB_NAME}",
					to: "${mailto}",
					body: "<b>Внимание!!!</b> <b><br>\n\nСообщение об ошибке:</b> ${error}\n\n <b><br>Project Name:</b> ${env.JOB_NAME} <b><br>\nBuild Number:</b> ${env.BUILD_NUMBER} <b><br>\nStage Name:</b> Prod-like <b><br>\nURL Build:</b> ${env.BUILD_URL}"
				deleteDir()
				throw err    
			}
			try {
			    sh ('''GIT_SSH_COMMAND='ssh -i ${jenkins_ssh_key} -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no' \
					git clone ${swarm_git_url}
					cd ${WORKSPACE}/swarm
					echo ${docker_registry}/${docker_image}:${BUILD_NUMBER} > tags/nginx-gost.version
					git config --global user.email "${swarm_git_mail}"
					git config --global user.name "${swarm_git_user}"
					git add --all
					git commit -m "Update version of nginx-gost"
					GIT_SSH_COMMAND='ssh -i ${jenkins_ssh_key} -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no' \
					git push origin master
					rm -rf ~/.gitconfig
				''')
			} catch(err) {
			    currentBuild.result = "FAILURE"
				String error = "${err}";
						
				mail charset: 'UTF-8',
					from: "${mailfrom}",
					mimeType: 'text/html',
					subject: "Ошибка Jenkins CI/CD: Имя проекта -> ${env.JOB_NAME}",
					to: "${mailto}",
					body: "<b>Внимание!!!</b> <b><br>\n\nСообщение об ошибке:</b> ${error}\n\n Ошибка обновления тэга версии!!!<b><br>Project Name:</b> ${env.JOB_NAME} <b><br>\nBuild Number:</b> ${env.BUILD_NUMBER} <b><br>\nStage Name:</b> Prod-like <b><br>\nURL Build:</b> ${env.BUILD_URL}"
				deleteDir()
				throw err
			} 
			try {
			    currentBuild.result = "SUCCESS"
			    mail charset: 'UTF-8',
					from: "${mailfrom}",
					mimeType: 'text/html',
					subject: "Сборка успешно завешена! Имя проекта -> ${env.JOB_NAME}",
					to: "${mailto}",
					body: "<b>Внимание!!!</b> <b><br>\n\nСборка успешно завешена!<b><br>Project Name:</b> ${env.JOB_NAME} <b><br>\nBuild Number:</b> ${env.BUILD_NUMBER} <b><br>\nStage Name:</b> Prod-like <b><br>\nURL Build:</b> ${env.BUILD_URL}"
				deleteDir()
			} catch(err) {
			    throw err
			}
        }
	}
}
