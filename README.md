# Set Walks Develop Environment
This script will set up takewalk develop environment using docker-apis

Feel free to contact zengw@theteam247.com

## Steps you should follow
1. Download this repo
2. get woi_prod.sql.gz and put it in files/
2. get ssl key files and put them in ssl/
3. Make sure public key in github, private key in ec2, refer: https://docs.github.com/en/github/authenticating-to-github/connecting-to-github-with-ssh
4. Set git username and email
```
git config --global user.name 'Your name' 
git config --global user.email 'Your email' 
```
5. Run script (do not use root): swde.sh launch
6. Edit host file both in your local computer and ec2, domains will show at the end

## script will make two folders:
`/home/ubuntu/walks-apis` api codes and docker configuration there

`/home/ubuntu/walks_frontend` vue codes there
