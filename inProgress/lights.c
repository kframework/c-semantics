#include <stdio.h>
typedef enum {green, yellow, red} state;
state lightNS = green;
state lightEW = red;
state lights[2] = {green, red};

// property(light0) = lights[0]
// property(light1) = lights[1]
// #pragma __ltl property(safe) = [] ~(lights[0] == red /\ lights[1] == red)
#pragma __ltl safety: [] ~(__atom(lights[0] == red) /\ __atom(lights[1] == red))
#pragma __ltl executing: <> __ltl_builtin(executing)

int nextState(int light){
	state other = lights[(light+1)%2];
	switch (lights[light]) {
		case(green):
			lights[light] = yellow;
			return 0;
		case(yellow):
			lights[light] = red;
			return 0;
		case(red):
			if (other == red) {
				lights[light] = green;
			}
			return 0;
	}
}

void printStates(void){
	printf("light0 = %d; ", lights[0]);
	printf("light1 = %d\n", lights[1]);
}

int main(void){
	int ticks = 0;
	printStates();
	while(ticks++ < 15){
		nextState(0) + nextState(1);
		printStates();
	}
}
/*@ 

*/
