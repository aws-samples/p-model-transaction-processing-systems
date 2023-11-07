# Installation and Execution

## Installation:
* Follow the instructions available on P Github repo to install P: [https://p-org.github.io/P/getstarted/install/](https://p-org.github.io/P/getstarted/install/)
* Download the contents of this Github repo to a new folder

## Compile
* Open terminal and cd into TPS directory inside the folder you downloaded the contents of the Github repo.
* Run following command to compile:
> p compile

## Execute Test Cases
* Open terminal and cd into TPS directory inside the folder you downloaded the contents of the Github repo.
* Run the following commands to run each test case with 10 iterations:
> p check -tc tcActivePassive -i 10  
> p check -tc tcActivePassiveFailover -i 10  
> p check -tc tcActivePassiveF1 -i 10  
> p check -tc tcActivePassiveF2 -i 10  
> p check -tc tcActivePassiveF3 -i 10  
> p check -tc tcActivePassiveF4 -i 10  
> p check -tc tcActivePassiveF5 -i 10  
> p check -tc tcActiveActive -i 10  
> p check -tc tcActiveActiveFailover -i 10  
> p check -tc tcActiveActiveF1 -i 10  
> p check -tc tcActiveActiveF2 -i 10  
> p check -tc tcActiveActiveF3 -i 10  
> p check -tc tcActiveActiveF4 -i 10  
> p check -tc tcActiveActiveF5 -i 10
> p check -tc tcWorkload1 -i 10  
> p check -tc tcWorkload1Failover -i 10  
> p check -tc tcWorkload1F1 -i 10  
> p check -tc tcWorkload1F2 -i 10  
> p check -tc tcWorkload1F3 -i 10  
> p check -tc tcWorkload1F4 -i 10  
