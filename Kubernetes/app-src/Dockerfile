# Adapted from node-express-mysql boilerplates
FROM node:26-alpine
WORKDIR /usr/src/app
COPY package*.json ./
RUN npm install --omit=dev
COPY . .

# Creating a new system user
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
# Changing owner
RUN chown -R appuser:appgroup .
#changing user
USER appuser

# Expose the API port
EXPOSE 8080
# Execute the application
CMD [ "node", "app.js" ]
