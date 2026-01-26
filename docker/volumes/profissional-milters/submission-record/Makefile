debug: target/debug/submission-record
	sudo -u postfix ./target/debug/submission-record

target/debug/submission-record: Cargo.toml src/**.rs
	cargo build

watch-build:
	find -name \*.rs | entr -cc cargo build

watch-run:
	find ./target/debug -name submission-record | entr -rcc bash -c "rm -f /var/spool/postfix/milter/submission-record.sock; /etc/init.d/postfix restart; sudo -u postfix ./target/debug/submission-record --config-file=/etc/milter/submission-record.ini"

release: target/release/submission-record
	cp target/x86_64-unknown-linux-gnu/release/submission-record ./bin

target/release/submission-record: Cargo.toml src/**.rs
	RUSTFLAGS='-C target-feature=+crt-static' cargo build --release --target x86_64-unknown-linux-gnu

