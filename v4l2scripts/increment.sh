#!/bin/bash

#increases the value of a v4l2 control given in $1
#if it's an int or bool control then it increases by a value given in
#controlsteps[] unless this would put it past the value in controlmaxes[]
#if it is a menu type then it goes to the next bigger selection unless
#it is already set to the biggestest value

fnincrement(){
  source lib.sh
  source camcontrols.txt;
  declare -i index='0';

  read index < <( fngetcontrol "$1" );
  if [ "$index" -ge '0' ];
  then
    declare input='';
    declare -i currentvalue='-1' nextvalue='-1';
    declare -i max="${controlmaxes[index]}" step="${controlsteps[index]}";
    declare -i min="${controlmins[index]}";

    read input< <( v4l2-ctl -d "$device" -C "$1" | cut -d ':' -f '2-' | egrep -o '[^ ].*' );
    [ "${#input}" -eq '0' ] && return '2';
    currentvalue="$input";
    (( nextvalue=step+currentvalue ));
    [ "$nextvalue" -lt "$min" ] && nextvalue="$min";
    [ "$nextvalue" -gt "$max" ] && nextvalue="$max";
    [ "$currentvalue" -ne "$nextvalue" ] && v4l2-ctl -d "$device" -c "$1"'='"$nextvalue";
  else
    read index < <( fngetmenu "$1" );
    if [ "$index" -ge '0' ];
    then
      declare -a options=( ${menuoptions[index]} );
      declare input='';
      declare -i optindex='0' optcnt="${#options[@]}" found='0';
      declare -i nextvalue='-1'  currentvalue='-1';

      read input< <( v4l2-ctl -d "$device" -C "$1" | cut -d ':' -f '2-' | egrep -o '[^ ].*' );
      [ "${#input}" -eq '0' ] && return '3';
      currentvalue="$input";

      while [ "$optindex" -lt "$optcnt" ] && [ "$found" -eq '0' ];
      do
        if [ "${options[optindex]}" -gt "$currentvalue" ];
        then
          nextvalue="${options[optindex]}";
          found='1';
        fi;
        (( ++optindex ));
      done;
      if [ "$found" -eq '0' ];
      then
        (( optindex=optcnt-1 ));
        nextvalue="${options[optindex]}";
      fi;
      [ "$currentvalue" -ne "$nextvalue" ] && v4l2-ctl -d "$device" -c "$1"'='"$nextvalue";
      return '0';
    else
      return '1';
    fi;
  fi;

  return '16';
};

fnincrement "$@";
