TARGET := example.out
CC     := dmd
OUT    := build

all: $(TARGET)

$(TARGET): ./source/app.d
	$(CC) -o $@ $^

clean:
	rm $(TARGET)
