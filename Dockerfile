FROM debian:trixie-20260505 AS downloader

RUN apt-get update && apt-get install -y rsync
RUN mkdir /libs; \
	ldd /usr/bin/rsync | grep '=>' | awk '{ print $3; }' | xargs -I_ -n 1 cp _ /libs; \
	ldd /bin/sleep | grep '=>' | awk '{ print $3; }' | xargs -I_ -n 1 cp _ /libs

FROM gcr.io/distroless/base-debian13
COPY --from=downloader /usr/bin/rsync /bin/sleep /usr/bin/
COPY --from=downloader /libs/* /usr/lib/
ENTRYPOINT ["/usr/bin/sleep", "infinity"]
