typedef enum {green, yellow, red} state;

state lightNS = green;
state lightEW = red;

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
	while(1) {
		changeNS() + changeEW();
	}
}
