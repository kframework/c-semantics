#include <stdio.h>
typedef enum {green, yellow, red} state;
state lightNS = green;
state lightEW = red;
//state lights[2] = {green, red};



#pragma __ltl safety: [] ~(__atom(lights[0] == red) /\ __atom(lights[1] == red))
#pragma __ltl executing: <> __ltl_builtin(executing)
#pragma __ltl simple: <> __atom(5)
#pragma __ltl simple2: __atom(4 + 5 == 9)
#pragma __ltl bad: __atom(4 + 4 == 9)
#pragma __ltl zero: __atom(0)
#pragma __ltl yellow: __atom(yellow)
#pragma __ltl var: <> __atom(ticks)
#pragma __ltl other: <> __atom(other)
#pragma __ltl liveness1: [] (__atom(lights[0] == red) -> <> __atom(lights[0] == green))

int changeNS(){
	switch (lightNS) {
		case(green):
			lightNS = yellow;
			return 0;
		case(yellow):
			lightNS = red;
			return 0;
		case(red):
			if (lightEW == red) {
				lightNS = green;
			}
			return 0;
	}
}
int changeEW(){
	switch (lightEW) {
		case(green):
			lightEW = yellow;
			return 0;
		case(yellow):
			lightEW = red;
			return 0;
		case(red):
			if (lightNS == red) {
				lightEW = green;
			}
			return 0;
	}
}

// void printStates(void){
	// printf("light0 = %d; ", lights[0]);
	// printf("light1 = %d\n", lights[1]);
// }

int main(void){
	//int ticks = 0;
	// printStates();
	//while(ticks++ < 15){
	while(1) {
		changeNS() + changeEW();
		//printStates();
	}
}
/*@ 

*/
