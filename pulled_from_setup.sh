
#SETUP IS WRONG THIS IS RUN
if ! source /root/CrummyArch/setup.conf; then
	# Loop through user input until the user gives a valid username
	while true
	do 
		read -p "Please enter username:" username
		username = 
		# username regex per response here https://unix.stackexchange.com/questions/157426/what-is-the-regex-to-validate-linux-users
		# lowercase the username to test regex
		if [[ "${username,,}" =~ ^[a-z_]([a-z0-9_-]{0,31}|[a-z0-9_-]{0,30}\$)$ ]]
		then 
			break
		fi 
		echo "Invalid username."
	done 
# convert name to lowercase before saving to setup.conf
echo "username=${username,,}" >> ${HOME}/CrummyArch/setup.conf

    #Set Password
    read -p "Please enter password:" password
echo "password=$password" >> ${HOME}/CrummyArch/setup.conf

    # Loop through user input until the user gives a valid hostname, but allow the user to force save 
	while true
	do 
		read -p "Please name your machine:" nameofmachine
		# hostname regex (!!couldn't find spec for computer name!!)
		if [[ "${nameofmachine,,}" =~ ^[a-z][a-z0-9_.-]{0,62}[a-z0-9]$ ]]
		then 
			break 
		fi 
		# if validation fails allow the user to force saving of the hostname
		read -p "Hostname doesn't seem correct. Do you still want to save it? (y/n)" force 
		if [[ "${force,,}" = "y" ]]
		then 
			break 
		fi 
	done 

    echo "nameofmachine=$nameofmachine" >> ${HOME}/CrummyArch/setup.conf
fi