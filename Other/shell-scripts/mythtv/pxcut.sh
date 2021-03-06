#!/bin/sh
# Copyright 2006, Kees Cook <kees@outflux.net>
# License: GNU GPL v2

MEDIA=""
DBSERVER="jmd0"
DBUSER="mythtv"
DBPASSWD="mythtv"
DB="mythconverg"

function update_filesize {
   FILESIZE=`du -b "${MEDIA}" | cut -f 1`
   if [ "${FILESIZE}" -gt 1000000 ]; then
      echo "update recorded set filesize=${FILESIZE} where basename='${BASENAME}.mpg';" | mysql -h ${DBSERVER} -u ${DBUSER} --password=${DBPASSWD} ${DB}
      mythcommflag -f "${MEDIA}" --clearcutlist
   fi
}

function update_database {
   update_filesize
   echo "DELETE FROM recordedmarkup WHERE chanid = $CHAN AND starttime = $START;" | mysql -h ${DBSERVER} -u ${DBUSER} --password=${DBPASSWD} ${DB}
   echo "update recorded set hostname='jmd1' where basename='${BASENAME}.mpg';" | mysql -h ${DBSERVER} -u ${DBUSER} --password=${DBPASSWD} ${DB}
   mythcommflag -f "${MEDIA}" --rebuild
   echo "update recorded set commflagged=0 where basename='${BASENAME}.mpg';" | mysql -h ${DBSERVER} -u ${DBUSER} --password=${DBPASSWD} ${DB}
}

function cutlist_x {
        #generate project x cutlist
        #cutlist is just a sequence of cutpoints
        #first entry is cut-in, i.e start recording
        line=0
        rm ${tempdir}/cutlist_x.txt 2>/dev/null
        cat ${tempdir}/cutlist.txt | while read
        do
                first=$(echo $REPLY|cut -f1 -d" ")
                second=$(echo $REPLY|cut -f2 -d" ")

                if [ "$line" -eq "0" ]; then
                        echo "CollectionPanel.CutMode=2" > ${tempdir}/cutlist_x.txt
                        if [ "$first" -ne "0" -a "$first" != "" ]; then
                                echo "0" >> ${tempdir}/cutlist_x.txt
                        fi
                fi
                line=$((line+1))
                if [ "$first" != "" -a "${first}0" -ne "0" ]; then
                        echo $first >> ${tempdir}/cutlist_x.txt
                fi
                if [ "$second" != "" ]; then
                        echo $second >> ${tempdir}/cutlist_x.txt
                fi
        done
}

function init_vars {
  MEDIA="$1"
  DEL=""
  EDL=`mktemp -t edl-XXXXXX`

  cat "$EDL"

  if [ ! -f "$MEDIA" ]; then
    echo "Play what mythtv recording?" >&2
    exit 1
  fi

  if [ "$2" != "" ]; then
    if [ $2 == "-d" ]; then
      DEL="true"
      echo "Processed recordings will be deleted"
    elif [ $2 == "-h" ]; then
      echo "USAGE $0 <filename.mpg> [-d] [-h]"
      exit
    fi
  fi

  ID=`echo "$MEDIA" | perl -ne 'print "$1 $2" if /(\d+)_(\d+)[^\d]+$/'`;
  CHAN=`echo "$ID" | awk '{print $1}'`
  CHAN=$(( CHAN + 0 ))
  START=`echo "$ID" | awk '{print $2}'`
  START=$(( START + 0 ))   

  BASENAME=${CHAN}_${START}

}

function perform_cut {
   if [ ! -f "$MEDIA".old ]; then
      mv "$MEDIA" "$MEDIA".old
      time projectx -demux -cut "${tempdir}"/cutlist_x.txt -out "${tempdir}" -name "${BASENAME}" "$MEDIA".old
      
      if ! [ -f "${tempdir}/${BASENAME}_log.txt" ]; then
        echo "Error running projectx, no log file created. giving up"
        exit 1
      fi

      if [ -f ${tempdir}/${BASENAME}.mp2 ]; then
        time mplex -o "${MEDIA}" -f 8 ${tempdir}/${BASENAME}.m2v ${tempdir}/${BASENAME}.mp2
      else
        time mplex -o "${MEDIA}" -f 8 ${tempdir}/${BASENAME}.m2v ${tempdir}/${BASENAME}.ac3
      fi

      if ! [ -f "${MEDIA}" ]; then
        echo "Error running mplex giving up."
        exit 1
      else
	rm ${tempdir}/${BASENAME}.m2v
        rm ${tempdir}/${BASENAME}.mp2
	rm $EDL

        if [ "$DEL" != "" ]; then
	   rm "$MEDIA".old
        fi

      fi

      update_database

   else
      echo "$MEDIA".old exists exiting
   fi
}

function generate_cutlist {
echo "SELECT mark FROM recordedmarkup WHERE chanid = $CHAN AND starttime = $START AND (type = 0 OR type = 1) ORDER BY mark;" | mysql -h ${DBSERVER} -u ${DBUSER} --password=${DBPASSWD} ${DB} -B --skip-column-names | xargs -n2 > "${EDL}"

VAL=`wc  "$EDL" | awk '{ print $1 }'`

cat "$EDL" 
echo "Val=" "$VAL"

if [ "$VAL" -gt 1 ]; then
   tempdir=/tmp/mpeg/${BASENAME}
   mkdir -p ${tempdir}
   cp "$EDL" ${tempdir}/cutlist.txt
   cutlist_x
else
   echo "$MEDIA does not have a cutlist for chanid= $CHAN and starttime= $START."
   update_filesize
   exit 1
fi
}


#set -e

init_vars $@

generate_cutlist

perform_cut 
