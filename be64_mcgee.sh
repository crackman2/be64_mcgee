#!/bin/sh

# Base64 encode and decode for ASCII strings

# Notes on padding:
# =  means discard last two  bits
# == means discard last four bits

# Notes on parameter expansion
# t="foo"
# echo "only first char   : ${t%${t#?}}"
# echo "all but first char: ${t#?}" 

#REGION_START




# Print shortcuts
_en(){ printf '%s\n' "$1"; }
_e(){ printf '%s' "$1"; }


#ARG: 1=binary string to add zeros to
#RET: bianry string with zeros added as
#     prefix to reach len=8
# ->  IN: 1100 OUT: 00001100
#USE: _convertCharToBinary
_prefixWithZeros(){
    __pxLen="${#1}"
    __pxPrefix="0"
    __pxI="$((8-__pxLen))"
    while [ "$__pxI" -gt 1 ]; do
	__pxPrefix="${__pxPrefix}0"
	__pxI="$((__pxI-1))"
    done
    _e "$__pxPrefix$1"
}

#ARG: 1=string with a single character
#RET: 8bit binary representation as string
_convertCharToBinary(){
    if [ "${#1}" -gt 1 ] || [ -z "$1" ]; then
	_en "[Error] input length > 1 or  = 0. only single char pls"
	exit 1
    fi

    # Convert character to decimal representation
    __cbDecimalValue="$(printf '%d' "'$1'")"
    __cbBinaryValue=

    # Convert decimal to binary like this:
    # num=5
    # 1.  5%2=[1]; num=(5-(5%2)/2)=(5-(1))/2=4/2=2
    # 2.  2%2=[0]; num=(2-(2%2)/2)=(2-(0))/2=2/2=1
    # 3.  prepend [1] because num equals 1
    # Result: 101; prepend zeros to reach char length of 8
    # Return: 00000101
    __cbI=1
    while :; do
	if [ "$__cbI" -gt 8 ]; then
	   _en "Error"
	fi
	__cbBinaryValue="$((__cbDecimalValue%2))$__cbBinaryValue"
	__cbDecimalValue="$((   (__cbDecimalValue - (__cbDecimalValue % 2)) / 2   ))"

	if [ "$__cbDecimalValue" -eq 1 ]; then
	    __cbBinaryValue="1${__cbBinaryValue}"
	    break
	fi
	__cbI="$((__cbI+1))"
    done
    
    _e "$(_prefixWithZeros $__cbBinaryValue)"
}


#ARG: 1=input
#RET: 1 on failure, nothing on success
#USE: _insertSpaceIntoString
_isNumber(){
    if [ -z "$1" ]; then return 1; fi
    if [ "$1" -eq "$1" ] 2> /dev/null; then return 0
    else return 1; fi
}


#ARG: 1=string
#     2=index (starting at 1) of char
#     to be prefixed with space.
#     index longer than string -> append space
#RET: string with space in it lol
# ->  IN: 1=10011001, 2=3
#     OUT: 10 011001
_insertSpaceIntoString(){
    if ! _isNumber "$2"; then
	_en "[Error] arg 2 is not a number"; exit
    fi
    
    __itI=1
    __itString="$1"
    __itSpaceInserted=
    __itResult=

    while [ -n "$__itString" ]; do
	# Append first char of input string to result
	# include space if the index equals the selected one
	if [ "$__itI" -eq "$2" ]; then
	    __itResult="$__itResult ${__itString%${__itString#?}}"
	    __itSpaceInserted=1
	else
	    __itResult="$__itResult${__itString%${__itString#?}}"
	fi
                
	# Drop first char of input string to
	# either gthe next one, or end the loop
	__itString="${__itString#?}"
	__itI="$((__itI+1))"
    done

    # Append space if index larger than string length
    if [ -z "$__itSpaceInserted" ]; then
	__itResult="$__itResult "
    fi
    _e "$__itResult"
}



#ARG: 1=input string to convert
#RET: string of binary representation
#     split into six-char long substrings
#     seprated with space. last element
#     may be shorter
# ->  IN              : hi
#     binary          : 01101000 01101001
#     split into len 6: 011010 000110 1001
_generateSplitBinaryString(){
    if [ -z "$1" ]; then
	_en "[Error] string can't be empty"; exit 1
    fi
    
    __gbString="$1"
    __gbResult=
    __gbSpacePos=7
    __gbSuffixSpace=
    # ${t%${t#?}} only first char
    # ${t#?}   all but first char
    # Convert chars to binary, add to list, add spaces
    while [ -n "$__gbString" ]; do
	#echo "string    : $__gbString"
	#echo "__gbCharBinary=$ (_convertCharToBinary ${__gbString%${__gbString#?}})"
	__gbCharBinary="$( _convertCharToBinary "${__gbString%${__gbString#?}}")"
	#echo "char bin  : $__gbCharBinary"
	#echo "spos      : $__gbSpacePos"
	#echo "bin spaced: $(_insertSpaceIntoString $__gbCharBinary $__gbSpacePos)"
	#echo "__gbResult=$ (_insertSpaceIntoString $__gbCharBinary $__gbSpacePos)"
	__gbResult="$__gbResult$(_insertSpaceIntoString "$__gbCharBinary" "$__gbSpacePos")$__gbSuffixSpace"
	#echo "__gbResult: $__gbResult"

	# Drop first character from input string
	__gbString="${__gbString#?}"

	# Adjust position of space for next binary string
	# and activate space suffix to avoid missing space
	# in __gbResult 
	case "$__gbSpacePos" in
	    7)__gbSpacePos=5;__gbSuffixSpace="";;
	    5)__gbSpacePos=3;__gbSuffixSpace=" ";;
	    3)__gbSpacePos=7;__gbSuffixSpace="";;
	    *)_en "[Error] __gbSpacePos somehow out of sequence."; exit;;
	esac
    done

    _e "$__gbResult"
}



#ARG: 1=6bit binary string
#     2= leave empty for binary -> letter
#        if $2 is assigned, letter -> binary
#RET: the corresponding base64 letter
_lookupBase64Alphabet(){
    __lbAlphabet="\
000000=A
000001=B
000010=C
000011=D
000100=E
000101=F
000110=G
000111=H
001000=I
001001=J
001010=K
001011=L
001100=M
001101=N
001110=O
001111=P
010000=Q
010001=R
010010=S
010011=T
010100=U
010101=V
010110=W
010111=X
011000=Y
011001=Z
011010=a
011011=b
011100=c
011101=d
011110=e
011111=f
100000=g
100001=h
100010=i
100011=j
100100=k
100101=l
100110=m
100111=n
101000=o
101001=p
101010=q
101011=r
101100=s
101101=t
101110=u
101111=v
110000=w
110001=x
110010=y
110011=z
110100=0
110101=1
110110=2
110111=3
111000=4
111001=5
111010=6
111011=7
111100=8
111101=9
111110=+
111111=/"

    while IFS='=' read -r __lbKey __lbVal; do
	if [ "$__lbKey" = "$1" ]; then
	    printf '%s' "$__lbVal"
	    break
	fi
    done <<EOF
$__lbAlphabet
EOF

}



#ARG: 1=ASCII input string
#RET: base64 encoded string
_encode(){
    if [ -z "$1" ]; then _en "[Error] arg must not be empty"; exit; fi

    echo '$1' "[$1]"
    __eBinary="$(_generateSplitBinaryString "$1")"
    echo "eBinary [$__eBinary]"
    __eResult=
    __ePadding=
    
    for __eSegment in $__eBinary; do
	
	if [ "${#__eSegment}" -ne 6 ]; then
	    case "${#__eSegment}" in
		4)
		    __eResult="$__eResult$(_lookupBase64Alphabet "${__eSegment}00")"
		    __ePadding='='
		    echo "Segment [${__eSegment}'00][${#__eSegment}][$(_lookupBase64Alphabet "${__eSegment}00")][=]"
		    ;;
		2)
		    __eResult="$__eResult$(_lookupBase64Alphabet "${__eSegment}0000")"
		    __ePadding='=='
		    echo "Segment [${__eSegment}'0000][${#__eSegment}][$(_lookupBase64Alphabet "${__eSegment}0000")][==]"
		    ;;
		*)_en "[Error] binary segment has invalid length somehow -> [$__eSegment]"; exit;;
	    esac
	else
	    __eResult="$__eResult$(_lookupBase64Alphabet "$__eSegment")"
	    echo "Segment [$__eSegment] [${#__eSegment}][$(_lookupBase64Alphabet "$__eSegment")]"
	fi
    done

    _e "$__eResult$__ePadding"
}



_encode "hello"
echo
echo
_encode "MMMMMMM"

#REGION_END
