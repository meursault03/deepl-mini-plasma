.pragma library

function quote(value) {
    return "'" + String(value).replace(/'/g, "'\\''") + "'"
}

function build(argumentsList) {
    return argumentsList.map(quote).join(" ")
}
