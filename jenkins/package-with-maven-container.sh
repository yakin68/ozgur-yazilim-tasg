docker run --rm -v $HOME/target:/root/target -v $WORKSPACE:/app -w /app maven:3.9.5-amazoncorretto-17 mvn clean package