# Adapted from node-express-mysql boilerplates
FROM node:26-alpine
WORKDIR /usr/src/app
COPY package*.json ./
RUN npm install --omit=dev
COPY . .
# Expose the API port
EXPOSE 8080
# Execute the application
CMD [ "node", "app.js" ]
