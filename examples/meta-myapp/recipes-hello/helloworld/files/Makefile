CC ?= gcc
CFLAGS ?= -Wall -O2
TARGET = helloworld
SOURCE = helloworld.c

all: $(TARGET)

$(TARGET): $(SOURCE)
	$(CC) $(CFLAGS) $(LDFLAGS) -o $(TARGET) $(SOURCE)

clean:
	rm -f $(TARGET)

.PHONY: all clean 