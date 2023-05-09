# epix-hr-m-320k

## Before you clone the GIT repository

1) Create a github account:
> https://github.com/

2) On the Linux machine that you will clone the github from, generate a SSH key (if not already done)
> https://help.github.com/articles/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent/

3) Add a new SSH key to your GitHub account
> https://help.github.com/articles/adding-a-new-ssh-key-to-your-github-account/

4) Setup for large filesystems on github (one-time operation)
> $ git lfs install

## Clone the GIT repository
``` $ git clone --recursive git@github.com:slaclab/epix-hr-m-320k.git```


## How to build the firmware

1) Setup Xilinx licensing
```
$ source epix-hr-m-320k/firmware/setup_env_slac.sh
```

2) If not done yet, make a symbolic link to the firmware/
```
$ ln -s /u1/$USER/build epix-hr-m-320k/firmware/build
```

3) Go to the target directory and make the firmware:
```
$ cd epix-hr-m-320k/firmware/targets/ePixHRM320k/
$ make
```

4) Optional: Review the results in GUI mode
```
$ make gui
```

## How to run simulation

1) Setup Xilinx licensing
```
$ source epix-hr-m-320k/firmware/setup_env_slac.sh
```

2) If not done yet, make a symbolic link to the firmware/
```
$ ln -s /u1/$USER/build epix-hr-m-320k/firmware/build
```

3) Go to the target directory and make the firmware:
```
$ cd epix-hr-m-320k/firmware/targets/ePixHRM320k/
$ make vcs
```

4) Execute the instructions provided by the previous command
give that it finished successfully.

5) In a new terminal run Rogue source script
```
$ source epix-hr-m-320k/software/setup_env_slac.sh
```

6) Run the python software
```
$ cd epix-hr-m-320k/software/scripts
$ python devGui.py --dev sim
```

## LEAP Transceiver Mapping


```
Lane[7:0] : serving core
Lane[11:8] : serving app


Lane[0].VC[0] = Data[0]
Lane[1].VC[0] = Data[1]
Lane[2].VC[0] = Data[2]
Lane[3].VC[0] = Data[3]
Lane[4].VC[0] = Spare
Lane[5].VC[0] = SRPv3
Lane[5].VC[1] = software trigger (ssiCmd)
Lane[5].VC[2] = XVC
-Lane[6].VC[0] = slow monitoring[1:0]
-    [1] = Power and Communication Board
-    [0] = Digital Board
Lane[7].VC[3:0] = o-scope[3:0]
Lane[10:8] = Reserved for edgeML
Lane[11] = LCLS-II Timing
```
