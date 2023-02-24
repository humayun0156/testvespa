

HOST_CONTAINER='<host name="__CONTAINER_HOST__.vespa-internal.testvespa.svc.cluster.local"> <alias>__CONTAINER_HOST__</alias> </host>'
SVC_CONTAINER_NODE='<node hostalias="__CONTAINER_HOST__" />'

# get current container hosts count
current_container_hosts=$(vespa-model-inspect hosts | grep '^vespa-container-' | wc -l)
#current_container_hosts=3
host_container=""
svc_container=""
for ((i=0; i<=current_container_hosts; i++));
do
  tmp=$(echo $HOST_CONTAINER | sed "s|__CONTAINER_HOST__|vespa-container-$i|g")
  host_container="$host_container\n$tmp"

  tmp=$(echo $SVC_CONTAINER_NODE | sed "s|__CONTAINER_HOST__|vespa-container-$i|g")
  svc_container="$svc_container\n$tmp"
done


TEMPLATE_PATH="/var/git-sources/testvespa/template"
APP_PATH="/var/git-sources/testvespa/app"


cat $TEMPLATE_PATH/hosts.xml | sed "s|__CONTAINER_HOSTS__|$host_container|g" > $APP_PATH/hosts.xml
cat $TEMPLATE_PATH/services.xml | sed "s|__CONTAINER_NODES__|$svc_container|g" > $APP_PATH/services.xml

# wait until the server is up
while [[ "$(curl -s -o /dev/null -w ''%{http_code}'' http://localhost:8080/ApplicationStatus)" != "200" ]];
do
  sleep 5;
  echo "$(date) : Application server has not up yet. waiting..."
done

/opt/vespa/bin/vespa-deploy prepare $APP_PATH && /opt/vespa/bin/vespa-deploy activate