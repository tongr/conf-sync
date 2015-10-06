#! /bin/bash
SCRIPT_DIR="$(cd "$(dirname ${BASH_SOURCE[0]})"; pwd)"
COMMENT="# executing synchronized script"

echo "Installing synchronized scripts from $SCRIPT_DIR ..."

while read line || [ -n "$line" ]
do
  if [[ ! -z  $line ]] && [[ ! $line =~ ^[[:space:]]*#.*$ ]]
  then
    KV=(${line//=/ })
    SOURCE="$SCRIPT_DIR/${KV[0]}"
    DESTINATION="${KV[1]}"
    echo "Installing $SOURCE scripts ..."
    for SCRIPT in $(ls -a $SOURCE)
    do
      CALL_LINE="source $SOURCE/$SCRIPT"
      if [ ! -d "${SCRIPT}" ]
      then
        if [ ! -e $DESTINATION/$SCRIPT ]
        then
          echo -e "$COMMENT\n$CALL_LINE" > $DESTINATION/$SCRIPT
        elif ! grep -q "$CALL_LINE" "$DESTINATION/$SCRIPT"
        then
          echo -e "$COMMENT\n$CALL_LINE" >> $DESTINATION/$SCRIPT
        fi
      fi
    done
  fi
done <$SCRIPT_DIR/sync.conf

echo "Installation finished!"