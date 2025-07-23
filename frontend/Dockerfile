FROM node:18 AS build
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build


FROM nginx:1.25-alpine


COPY --from=build /app/build /usr/share/nginx/html

RUN rm /etc/nginx/conf.d/default.conf
COPY nginx.conf /etc/nginx/conf.d/

# wiztextexercise.txt 
RUN echo "--- AI Pictionary Rules ---" > /usr/share/nginx/html/wizexercise.txt && \
    echo "" >> /usr/share/nginx/html/wizexercise.txt && \
    echo "1. The AI will give you something to draw." >> /usr/share/nginx/html/wizexercise.txt && \
    echo "2. Draw the object on the canvas." >> /usr/share/nginx/html/wizexercise.txt && \
    echo "3. The AI will try to guess what you are drawing." >> /usr/share/nginx/html/wizexercise.txt && \
    echo "4. Points are awarded for correct guesses!" >> /usr/share/nginx/html/wizexercise.txt && \
    echo "5. See if you can get the high score on the leaderboard!" >> /usr/share/nginx/html/wizexercise.txt


EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]