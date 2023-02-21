#!/bin/bash
############################################################
# Help                                                     #
############################################################
Help()
{
   # Display Help
   echo "SCRIPT PARA CREAR EL MANIFEST FILE DE UNA CARPETA DEL BUCKET"
   echo "Y SUBIR EL MANIFEST FILE A LA MISMA CARPETA"
   echo
   echo "Options:"
   echo "-f <folder_name>    Name of the folder from wich manifest is created and uploaded "
   echo "-h                  Print this Help"
   echo
   echo "USAGE EXAMPLE: "
}

############################################################
# CheckRequiredOptions                                     #
############################################################
CheckRequiredOptions()
{

if [ -z ${FOLDER_NAME} ]; then
  echo "ERROR: MISSING ARGUMENT -f "
  exit 1;
fi

}

############################################################
############################################################
# Main program                                             #
############################################################
############################################################

while getopts "f::h" option; do
        case $option in
                f) FOLDER_NAME=$OPTARG;;
                h) Help
                   exit;;
                *)
                   exit;;
        esac
done

CheckRequiredOptions

#1-Crear dir donde montar
echo "Creando directorio donde montar la carpeta del bucket"
mkdir $HOME/mount/gcp/$FOLDER_NAME
if [ $? == 1 ]; then
  echo "Error creando directorio donde montar la carpeta del bucket"
  exit 1;
fi

#2-Crear dir donde almacenar temporalmente el manifest
echo "Creando directorio donde almacenar temporalmente el manifest"
mkdir $HOME/tmp_storage/mount/$FOLDER_NAME
if [ $? == 1 ]; then
  echo "Error creando directorio donde almacenar temporalmente el manifest"
  exit 1;
fi

#3-Montar bucket
echo "Montando bucket"
gcsfuse --only-dir $FOLDER_NAME/ --implicit-dirs --key-file $HOME/mount/gcp/image-store-key.json mindcolab-image-store $HOME/mount/gcp/$FOLDER_NAME
if [ $? == 1 ]; then
  echo "Error montando bucket"
  exit 1;
fi

#4-Activar entorno
echo "Activando entorno"
. $HOME/cvat_manifest/bin/activate
if [ $? == 1 ]; then
  echo "Error activando entorno"
  exit 1;
fi

#5-Crear manifest
echo "Creando manifest"
python $HOME/cvat/utils/dataset_manifest/create.py --output-dir $HOME/tmp_storage/mount/$FOLDER_NAME/ $HOME/mount/gcp/$FOLDER_NAME/
if [ $? == 1 ]; then
  echo "Error creando manifest"
  exit 1;
fi

#6-Desactivar entorno
echo "Desactivando entorno"
deactivate
if [ $? == 1 ]; then
  echo "Error desactivando entorno"
  exit 1;
fi

#7-Desmontar bucket
echo "Desmontando bucket"
fusermount -u $HOME/mount/gcp/$FOLDER_NAME
if [ $? == 1 ]; then
  echo "Error desmontando bucket"
  exit 1;
fi

#8-Subir manifest file al bucket
echo "Subiendo manifest file a la carpeta del bucket"
gsutil cp $HOME/tmp_storage/mount/$FOLDER_NAME/manifest.jsonl gs://mindcolab-image-store/$FOLDER_NAME
if [ $? == 1 ]; then
  echo "Error subiendo manifest file a la carpeta del bucket"
  exit 1;
fi

#9-Borrar directorio donde se monto
echo "Borrando directorio donde se monto"
rm -d $HOME/mount/gcp/$FOLDER_NAME/
if [ $? == 1 ]; then
  echo "Error borrando directorio donde se monto"
  exit 1;
fi

#10-Borrar directorio y manifest file del almacenamiento temporal
echo "Borrando directorio y manifest file del almacenamiento temporal"
rm -rf $HOME/tmp_storage/mount/$FOLDER_NAME/
if [ $? == 1 ]; then
  echo "Error borrando directorio y manifest file del almacenamiento temporal"
  exit 1;
fi

echo "MANIFEST FILE CREADO Y SUBIDO AL FOLDER DEL BUCKET EXITOSAMENTE"
