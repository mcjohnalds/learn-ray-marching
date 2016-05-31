class Stopwatch {
    constructor() {
        this.running = true; // Is
        this.lastStartedAt = 0;
        this.lastPausedAt = 0;
    }

    start() {
        if (!this.running) {
            this.running = true;
            this.lastStartedAt = this.currentTime();
        }
    }

    pause() {
        if (this.running) {
            this.running = false;
            this.lastPausedAt = this.lastPausedAt + this.currentTime() - this.lastStartedAt;
        }
        this.lastStartedAt = 0;
    }

    reset() {
        this.running = false;
        this.lastStartedAt = 0;
        this.lastPausedAt = 0;
    }

    seconds() {
        if (this.running)
            return this.lastPausedAt + this.currentTime() - this.lastStartedAt;
        else
            return this.lastPausedAt;
    }

    currentTime() {
        return Date.now() / 1000;
    }
}
