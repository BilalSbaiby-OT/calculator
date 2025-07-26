#include <stdio.h>



float add(float a, float b){
    return a + b;
}
float minus(float a, float b){
    return a - b;
}
float cross(float a, float b){
    return a * b;
}
float split(float a, float b){
    return a / b;
}
void choices(){
    printf("[1]  +\n");
    printf("[2]  -\n");
    printf("[3]  *\n");
    printf("[4]  /\n");

}
int main(){
    int choice;
    float a, b, result;

    choices();
    printf(">> ");
    scanf("%d", &choice);

    printf("First number >> ");
    scanf("%f", &a);
    printf("Second number >> ");
    scanf("%f", &b);

    switch (choice) {
        case 1:
            result = add(a, b);
            break;
        case 2:
            result = minus(a, b);
            break;
        case 3:
            result = cross(a, b);
            break;
        case 4:
            if (b == 0) {
                printf("Error: division by zero\n");
                return 1;
            }else{
            result = split(a, b);
            break;
            }

        default:
            printf("Invalid choice\n");
            return 1;
    }

    printf("Result: %f\n", result);
    return 0;
}