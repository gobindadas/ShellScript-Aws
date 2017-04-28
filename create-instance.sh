#!/bin/bash
# Author: Gobinda Das
# Email: gobindamca2011@gmail.com.com

 	imageid="$1" 
	instance_type="$2"
	key_name="$3" 
	security_group="$4"
	subnet="$5"
	tag="$6"
 	user="$7"
	pemfileLocation="$8"
 	chefLocation="$9"
 	currentDir="$PWD"

 create_instance(){
	count=1

	# Create Instance and return Instance Id
	instance_id=$(aws ec2 run-instances --image-id $imageid --security-group-ids $security_group --subnet-id $subnet --count $count --instance-type $instance_type --key-name $key_name --output text --query 'Instances[*].InstanceId')
	# Update Tag in created Instance
	$(aws ec2 create-tags --resources $instance_id --tags $tag)
	echo "Wait for 2 mins to Instance up."
	sleep 120
	# Find Public Ip
	ipAddress=$(aws ec2 describe-instances --instance-ids $instance_id --output text --query 'Reservations[*].Instances[*].PublicIpAddress')
	if [ $ipAddress ]
	then
		echo PublicIpAddress: $ipAddress
	else
		# Find Private Ip if Public Ip not available
		ipAddress=$(aws ec2 describe-instances --instance-ids $instance_id --output text --query 'Reservations[*].Instances[*].PrivateIpAddress')
		echo PrivateIpAddress: $ipAddress
	fi

	bootstrap_node $ipAddress
 }

 bootstrap_node(){
  	echo "Node bootstrap started to install docker...."
  	cd $chefLocation
  	sudo knife bootstrap -i $pemfileLocation -x $user --sudo $ipAddress -r 'recipe[docker_rl]'
  	echo "Node bootstrap finished...."
  	cd $currentDir
  	pwd
  	run_docker_nginx $ipAddress
  }

run_docker_nginx(){
	echo "Creating nginx container...."
 	runCommand="sudo docker run -t -i -d -p 80:80 --name nginx relevancelab/rlnginx:1.0.0"

	sudo ssh -i "$pemfileLocation" "$user"@"$ipAddress" "$runCommand"
	echo "Nginx container created..."
	run_docker_mysql $ipAddress
 }

run_docker_mysql(){
	echo "Creating mysql container...."
	runCommand="sudo docker run --name mysql -e MYSQL_ROOT_PASSWORD=password -d mysql"

	sudo ssh -i "$pemfileLocation" "$user"@"$ipAddress" "$runCommand"
	echo "Mysql container created..."
	run_docker_wordpress $ipAddress
}

run_docker_wordpress(){
	echo "Creating Wordpress container...."
	runCommand="sudo docker run --name wordpress -p 8080:80 --link mysql:mysql -d -e WORDPRESS_DB_PASSWORD=password wordpress"

	sudo ssh -i "$pemfileLocation" "$user"@"$ipAddress" "$runCommand"
	echo "Wordpress container created..."
	add_domain $ipAddress
}

 add_domain(){
 	echo "add_domain....."
 	$(sudo python modify-json.py $ipAddress)
	$(aws route53 change-resource-record-sets --hosted-zone-id Z2BRKRLMFMHOFF --change-batch file://change-resource-record-sets.json)
  }

create_instance
