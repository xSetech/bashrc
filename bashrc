function fn () {
    find . -name "${1}"
}

function gr () {
    for branch in `git branch -r | grep -v HEAD`; do
        echo -e `git show --format="%ci %cr" $branch | head -n 1` \\t$branch;
    done | sort -r
}

function cdtmp() {
    CDTMPDIR=${CDTMPDIR:-$(mktemp -d)}
    pushd $CDTMPDIR
}

# ---
# OPTIONAL SOFTWARE
# ---

# Software is installed with prefixes in $LOCAL/opt/.
# Actively used software have their prefixes symlinked as $LOCAL/active/<x> -> $LOCAL/opt/<x>.
# The symlinks in $LOCAL/active become entries in each environment variable (via set_experimental_env())
function configure_active_optional_software() {

    export ACTIVE_OPTIONALS_PATH=""
    export ACTIVE_OPTIONALS_LD_LIBRARY_PATH=""
    export ACTIVE_OPTIONALS_LDFLAGS=""
    export ACTIVE_OPTIONALS_CPPFLAGS=""
    export ACTIVE_OPTIONALS_MANPATH=""
    export ACTIVE_OPTIONALS_PKGCONFIG=""

    if [[ -d $LOCAL/active ]]; then

        echo "" >&2
        echo "Active optional software:" >&2

        pushd $LOCAL/active > /dev/null
        for active_entry in $(ls); do

            echo " * ${active_entry}" >&2

            if [[ -L ${active_entry} ]]; then
                local active_entry_abs_path=$(greadlink -m ${active_entry})
                if [[ -e ${active_entry_abs_path} ]]; then

                    if [[ -e ${active_entry_abs_path}/bin ]]; then
                        export ACTIVE_OPTIONALS_PATH="${ACTIVE_OPTIONALS_PATH}:${active_entry_abs_path}/bin"
                    fi

                    if [[ -e ${active_entry_abs_path}/sbin ]]; then
                        export ACTIVE_OPTIONALS_PATH="${ACTIVE_OPTIONALS_PATH}:${active_entry_abs_path}/sbin"
                    fi

                    if [[ -e ${active_entry_abs_path}/lib ]]; then
                        export ACTIVE_OPTIONALS_LD_LIBRARY_PATH="${ACTIVE_OPTIONALS_LD_LIBRARY_PATH}:${active_entry_abs_path}/lib"
                        export ACTIVE_OPTIONALS_LDFLAGS="${ACTIVE_OPTIONALS_LDFLAGS} -L${active_entry_abs_path}/lib"
                    fi

                    if [[ -e ${active_entry_abs_path}/lib64 ]]; then
                        export ACTIVE_OPTIONALS_LD_LIBRARY_PATH="${ACTIVE_OPTIONALS_LD_LIBRARY_PATH}:${active_entry_abs_path}/lib64"
                        export ACTIVE_OPTIONALS_LDFLAGS="${ACTIVE_OPTIONALS_LDFLAGS} -L${active_entry_abs_path}/lib64"
                    fi

                    if [[ -e ${active_entry_abs_path}/include ]]; then
                        export ACTIVE_OPTIONALS_CPPFLAGS="${ACTIVE_OPTIONALS_CPPFLAGS} -I${active_entry_abs_path}/include"
                    fi

                    if [[ -e ${active_entry_abs_path}/share/man ]]; then
                        export ACTIVE_OPTIONALS_MANPATH="${ACTIVE_OPTIONALS_MANPATH}:${active_entry_abs_path}/share/man"
                    fi

                    if [[ -e ${active_entry_abs_path}/pkgconfig ]]; then
                        export ACTIVE_OPTIONALS_PKGCONFIG="${ACTIVE_OPTIONALS_PKGCONFIG}:${active_entry_abs_path}/pkgconfig"
                    fi

                    if [[ -e ${active_entry_abs_path}/lib/pkgconfig ]]; then
                        export ACTIVE_OPTIONALS_PKGCONFIG="${ACTIVE_OPTIONALS_PKGCONFIG}:${active_entry_abs_path}/lib/pkgconfig"
                    fi

                    if [[ -e ${active_entry_abs_path}/share/pkgconfig ]]; then
                        export ACTIVE_OPTIONALS_PKGCONFIG="${ACTIVE_OPTIONALS_PKGCONFIG}:${active_entry_abs_path}/share/pkgconfig"
                    fi

                fi
            fi
        done
        popd > /dev/null

        echo "" >&2
    fi
}

# Create env vars for active optional software
# Use "EXPERIMENTAL=false" to get a standard shell without optionals.
export EXPERIMENTAL="${EXPERIMENTAL:-true}"
if $EXPERIMENTAL ; then
    export LOCAL=$(readlink -m ~/Local)
    configure_active_optional_software
    export PATH="$LOCAL/bin:$LOCAL/sbin:${ACTIVE_OPTIONALS_PATH}:$(cat ~/PATH)"
    export MANPATH="$LOCAL/share/man:${ACTIVE_OPTIONALS_MANPATH}:/usr/share/man"
    export LD_LIBRARY_PATH="$LOCAL/lib64:$LOCAL/lib:${ACTIVE_OPTIONALS_LD_LIBRARY_PATH}"
    export LDFLAGS="-L$LOCAL/lib64 -L$LOCAL/lib ${ACTIVE_OPTIONALS_LDFLAGS}"
    export CPPFLAGS="-I$LOCAL/include ${ACTIVE_OPTIONALS_CPPFLAGS}"
    export PKG_CONFIG_PATH="$LOCAL/lib/pkgconfig:${ACTIVE_OPTIONALS_PKGCONFIG}"
fi
