
# Sale End Date
addTokenSale function now accepts a duration parameter (in seconds) to specify how long the sale will last from the time of creation. For example:
For mainnet, pass 7 * 24 * 60 * 60 (7 days in seconds).
For testing, pass a smaller value like 5 * 60 (5 minutes in seconds).