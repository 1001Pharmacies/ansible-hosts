# verify that needed functions are loaded
type git_branch >/dev/null 2>&1 || source /etc/profile.d/bash_functions.sh

# load personal stuffs
for user_file in .bash_aliases .bash_functions; do
    [ -f "${HOME}/${user_file}" ] && source "${HOME}/${user_file}"
done

# if we are in a terminal and automatic stuffs are enabled
if [ -t 0 -a -d ${HOME}/.ssh/auto ]; then
    for user_func in ${HOME}/.ssh/auto/*; do
        # search for files
        [ -f ${user_func} ] && func_name="$(basename ${user_func})" || continue
        # func_name should start with a letter (allow to order function calls with file names starting with numbers)
        while [ "${func_name}" != "" -a "${func_name#[a-z]}" = "${func_name}" ]; do
            # remove first char of func_name
            func_name="${func_name#?}"
        done
        # call user function with args passed from the content of the file
        [ -n "${func_name}" ] && ${func_name} $(cat ${user_func}) 2>/dev/null
    done
fi
