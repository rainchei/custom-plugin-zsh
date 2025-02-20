##
## helm-diff
##
export HELM_DIFF_IGNORE_UNKNOWN_FLAGS=true

##
## sops
##
export SOPS_AGE_KEY_FILE=~/.age/key.txt

##
## psql
##
function k-run-psql() {
  image="postgres:14.2"
  t=$(date +%s)

  # exec script
  if [[ $# -ge 3 ]]; then
    if [[ ! -f $3 ]]; then
      echo 1>&2 "[ERROR] $3 not found"
      return 1
    else
      echo "copying $(basename $3) to configmap/tmp-psql-$t ..." \
      && kubectl create configmap tmp-psql-$t --from-file=$3 \
      && echo "executing $(basename $3) to $1 ..." \
      && echo "------------------" \
      && kubectl run tmp-psql-$t --restart=Never --rm --tty -i \
          --image placeholder \
          --overrides='{"spec":{"containers":[{"image":"'$image'","name":"tmp-psql","command":["psql","--host","'$1'","-U","postgres","-f","'/etc/tmp-psql/$(basename $3)'"],"env":[{"name":"PGPASSWORD","value":"'$2'"},{"name":"PGSSLMODE","value":"prefer"}],"volumeMounts":[{"mountPath":"/etc/tmp-psql","name":"tmp-psql"}]}],"volumes":[{"configMap":{"name":"'tmp-psql-$t'"},"name":"tmp-psql"}]}}' \
      && kubectl delete configmap tmp-psql-$t
    fi

  # psql mode
  elif [[ $# -ge 2 ]]; then
    kubectl run tmp-psql-$t --restart=Never --rm --tty -i \
      --image $image \
      --env="PGPASSWORD=$2" \
      --env="PGSSLMODE=prefer" \
      --command -- psql --host $1 -U postgres

  # interactive mode
  elif [[ $# -ge 1 ]]; then
    if [[ ! "-it" == "$1" ]]; then
      echo 1>&2 "[ERROR] $1 not recognized"
      return 1
    else
      kubectl run tmp-psql-$t --restart=Never --rm --tty -i \
        --image $image \
        --env="PGSSLMODE=prefer" \
        --command -- bash
    fi
  else
    echo 1>&2 "usage: $0 [-it] <pg-host-name> <pgpassword> [<script.sql>]"
    return 1
  fi
}
