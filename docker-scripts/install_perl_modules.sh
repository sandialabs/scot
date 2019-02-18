while read p; do

        echo "--"
        echo "-- 1st attempt at installing $p"
        echo "--"

        cpanm $p

        if [[ $? == 1 ]]; then
            echo "!!!"
            echo "!!! $p failed install!  Will re-attempt later..."
            echo "!!!"
            RETRY="$RETRY $p"
        else
            echo "-- installed $p"
            echo "--"
        fi
    done < /opt/scot/perl/modules.txt

while read p; do
        echo "--"
        echo "-- 2nd attept to install $p"
        echo "--"
        cpanm $p

        if [[ $? == 1 ]]; then
            echo "!!! !!!"
            echo "!!! !!! final attempt to install $p failed!"
            echo "!!! !!! user intervention will be required"
            echo "!!! !!!"
            FAILED="$FAILED $p"
        fi
    done

    if [[ "$FAILED" != "" ]]; then
        echo "================ FAILED PERL MODULES ================="
        echo "The following list of modules failed to install.  "
        echo "Unfortunately they are necessary for SCOT to work."
        echo "Try installing them by hand: \"sudo -E cpanm module_name\""
        echo "Google any error messages or contact scot-dev@sandia.gov"
        for module in $FAILED; do
            if [[ $module == "AnyEvent::ForkManager" ]]; then
                echo "- forcing the install of AnyEvent::ForkManager"
                cpanm -f AnyEvent::ForkManager
            else 
                echo "    => $module"
            fi
        done
    fi

