#!/bin/bash
############################################################
# Help                                                     #
############################################################
Help()
{
   # Display Help
   echo "SCRIPT PARA MOVER LOS ARCHIVOS DEL TEMP STORAGE"
   echo "HACIA EL BUCKET DE GOOGLE"
   echo
   echo "Options:"
   echo "-d <upload_date>    File upload date"
   echo "-u <user_id>        Id of the user who uploaded the files"
   echo "-h                  Print this Help"
   echo
   echo "USAGE EXAMPLE: "
}

############################################################
# CheckRequiredOptions                                     #
############################################################
CheckRequiredOptions()
{

if [ -z ${UPLOAD_DATE} ]; then
  echo "ERROR: FALTA EL PARAMETRO -d"
  exit 1;
fi

if [ -z ${USER_ID} ]; then
  echo "ERROR: FALTA EL PARAMETRO -u"
  exit 1;
fi

}

############################################################
############################################################
# Main program                                             #
############################################################
############################################################

while getopts "d:u::h" option; do
        case $option in
                d) UPLOAD_DATE=$OPTARG;;
                u) USER_ID=$OPTARG;;
                h) Help
                   exit;;
                *)
                   exit;;
        esac
done

CheckRequiredOptions


if [[ ! -d "$HOME/tmp_storage/$USER_ID" ]]
then
  echo "Creando directorio..."
  mkdir "$HOME/tmp_storage/$USER_ID"
fi

docker cp ojo-seco-ui:/python-docker/instance/tmp_storage/$USER_ID/$UPLOAD_DATE $HOME/tmp_storage/$USER_ID
if [ $? == 1 ]; then
  echo "ERROR COPIANDO EL DIRECTORIO DESDE EL CONTENEDOR A LA VM"
  exit 1;
fi

docker exec -it ojo-seco-ui /python-docker/remove_dir.sh -d /python-docker/instance/tmp_storage/$USER_ID/$UPLOAD_DATE
if [ $? == 1 ]; then
  echo "ERROR BORRANDO EL DIRECTORIO EN EL CONTENEDOR, RECORDAR ELIMINAR MANUALMENTE"
  #exit 1;
fi

gsutil cp -r $HOME/tmp_storage/$USER_ID/$UPLOAD_DATE gs://inferencia-ojo-seco-bucket/tmp_storage/$USER_ID/$UPLOAD_DATE
if [ $? == 1 ]; then
  echo "ERROR SUBIENDO LOS ARCHIVOS AL BUCKET"
  exit 1;
fi

rm -rf $HOME/tmp_storage/$USER_ID/$UPLOAD_DATE

echo "ARCHIVOS SUBIDOS AL BUCKET EXITOSAMENTE"
