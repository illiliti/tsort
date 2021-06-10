#!/bin/sh
#
# Pure POSIX shell implementation of topological
# sort using recursive DFS(aka Tarjan's) algorithm
#
# globbing is disabled
# shellcheck disable=2086

contains()
{
    n=$1; arr=$2; _n=''

    IFS="${3:-" "}"; set -- $arr; unset IFS
    # TODO     ^ figure out what the hell is going on here    

    for _n; do
        if [ "$_n" = "$n" ]; then
            return 0
        fi
    done

    return 1
}

add_vertex()
{
    v_ve=''; v_v=$1

    for v_ve in $graph; do
        if [ "${v_ve%%:*}" = "$v_v" ]; then
            return 0
        fi
    done

    graph="$graph $v_v:"
    return 0
}

add_edge()
{
    e_v=$1; e_ve=''; e_e=$2; _g=''; _e=''; ok=0

    add_vertex "$e_v"
    add_vertex "$e_e"

    for e_ve in $graph; do
        if [ "${e_ve%%:*}" != "$e_v" ]; then
            _g="$_g $e_ve"
            continue
        fi

        _e="${e_ve##*:}"

        if contains "$e_e" "$_e" ','; then
            break
        fi

        if [ "$_e" ]; then
            _e="$_e,"
        fi

        _g="$_g $e_v:$_e$e_e"
        : "$(( ok += 1 ))"
    done

    if [ "$ok" -eq 1 ]; then
        graph="$_g"
    fi

    return 0
}

get_edges()
{
    g_ve=''; g_v=$1

    for g_ve in $graph; do
        if [ "${g_ve%%:*}" = "$g_v" ]; then
            break
        fi
    done

    printf "%s\n" "${g_ve##*:}"
    return 0
}

join()
{
    s=''; _s=''; _j=$2

    set -- $1

    for s; do
        _s="$_j$s$_s"
    done

    printf "%s" "${_s#$_j}"
    return 0
}

traversal()
{
    if contains "$1" "$black"; then
        return 0
    fi

    grey="$1 $grey"

    # pre-order
    order="$order $1"

    IFS=','; set -- $2; unset IFS

    # for loop cannot be used due to globals
    while [ "$1" ]; do
        if contains "$1" "$black"; then
            :
        elif contains "$1" "$grey"; then
            printf "%s: endless loop: %s\n" "$0" "$(join "$1 $grey" '>')"
            exit 1
        else 
            traversal "$1" "$(get_edges "$1")"
        fi

        shift 1
    done

    set -- $grey

    # post-order
    # order="$order $1"
    
    black="$black $1"

    shift 1
    grey="$*"

    return 0
}

populate_graph()
{
    set -- $1

    for t; do
        if [ ! "$v" ]; then
            v=$t
            add_vertex "$v"
        elif [ "$v" != "$t" ]; then
            add_edge "$v" "$t"
            v=''
        else
            v=''
        fi
    done
}

usage()
{
    printf "usage: %s [<file>]\n" "$0"
    exit "$1"
}

set -ef

if [ "$2" ]; then
    usage 2
elif [ "$1" = -h ]; then
    usage 0
elif [ "$1" ]; then
    while read -r var; do
        populate_graph "$var"
    done < "$1"
else
    while read -r var; do
        populate_graph "$var"
    done
fi

if [ "$v" ]; then
    printf "%s: input contains odd number of elements" "$0"
    exit 1
fi

for ve in $graph; do
    traversal "${ve%%:*}" "${ve##*:}"
done

for o in $order; do
    printf "%s\n" "$o"
done
