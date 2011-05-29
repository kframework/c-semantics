#include <stdio.h>
typedef enum {green, yellow, red} state;
state lightNS = green;
state lightEW = red;
state lights[2] = {green, red};

// property(light0) = lights[0]
// property(light1) = lights[1]
/*@ __property(safe) = [] ~(lights[0] == red /\ lights[1] == red) */

void nextState(int light){
	state other = lights[(light+1)%2];
	switch (lights[light]) {
		case(green):
			lights[light] = yellow;
			return;
		case(yellow):
			lights[light] = red;
			return;
		case(red):
			if (other == red) {
				lights[light] = green;
			}
			return;
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
		nextState(0);
		nextState(1);
		printStates();
	}
}
/*@ 

*/
