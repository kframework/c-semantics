typedef enum {green, yellow, red} state;
// #define green 0
// #define yellow 1
// #define red 2
//typedef int state;
state lightNS = green;
state lightEW = red;
// true
#pragma __ltl safety: [] (__ltl_builtin(executing) -> ( (__atom(lightNS == red) \/ __atom(lightEW == red))))
#pragma __ltl acolorNS: [] (__ltl_builtin(executing) -> (__atom(lightNS == green) \/ __atom(lightNS == yellow) \/ __atom(lightNS == red)))
#pragma __ltl acolorEW: [] (__ltl_builtin(executing) -> (__atom(lightEW == green) \/ __atom(lightEW == yellow) \/ __atom(lightEW == red)))

#pragma __ltl progress1: [] <> __atom(lightNS == green)
#pragma __ltl progress2: [] <> __atom(lightEW == red)
#pragma __ltl progress3: [] <> __atom(lightNS == red)
#pragma __ltl progress4: [] <> __atom(lightEW == yellow)


#pragma __ltl livenessNS: [] ((__ltl_builtin(executing) /\ __atom(lightNS == red)) -> <> __atom(lightNS == green))
#pragma __ltl livenessEW: [] ((__ltl_builtin(executing) /\ __atom(lightEW == red)) -> <> __atom(lightEW == green))

#pragma __ltl d: [] (__atom(lightNS == green) -> (__atom(lightNS == green) U __atom(lightNS == yellow)))
#pragma __ltl e: [] <> (__atom(lightNS == yellow) U __atom(lightNS == red))
#pragma __ltl f: [] <> (__atom(lightNS == red) U __atom(lightNS == green))



// #pragma __ltl liveness2: [] (__atom(lightEW == red) -> <> __atom(lightEW == green))
#pragma __ltl a: [] (__ltl_builtin(executing) -> __atom(lightEW == red))
#pragma __ltl b: [] (__ltl_builtin(executing) -> __atom(lightEW != green))
#pragma __ltl c: [] (__ltl_builtin(executing) -> __atom(lightNS != red))


#pragma __ltl executing: <> __ltl_builtin(executing)
#pragma __ltl simple: <> __atom(5)
#pragma __ltl simple2: __atom(4 + 5 == 9)
#pragma __ltl bad: __atom(4 + 4 == 9)
#pragma __ltl zero: __atom(0)
#pragma __ltl yellow: __atom(yellow)
#pragma __ltl var: <> __atom(ticks)
#pragma __ltl other: <> __atom(other)
#pragma __ltl part: <> __atom(lightNS == red)

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

int main(void){
	//int ticks = 0;
	// printStates();
	//while(++ticks < 7){
	while(1) {
		changeNS() + changeEW();
	}
}
