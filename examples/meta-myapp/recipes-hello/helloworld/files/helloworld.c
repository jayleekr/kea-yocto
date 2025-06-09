#include <stdio.h>
#include <stdlib.h>

int main(int argc, char *argv[])
{
    printf("Hello, Yocto World!\n");
    printf("이것은 Yocto 5.0 LTS 강의용 예제 프로그램입니다.\n");
    printf("빌드 날짜: %s %s\n", __DATE__, __TIME__);
    
    if (argc > 1) {
        printf("전달받은 인수: ");
        for (int i = 1; i < argc; i++) {
            printf("%s ", argv[i]);
        }
        printf("\n");
    }
    
    return 0;
} 