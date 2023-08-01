# -------------------------------------------------------------------- build ---

FROM python:3.8 as build

RUN apt-get update && apt-get install -y zip

WORKDIR /app

ADD requirements.txt /tmp
RUN pip install -t /app -r /tmp/requirements.txt

ADD src/ /app/
RUN find /app -type d | xargs -n 1 -I {} chmod ugo+rx "{}" && \
    find /app -type f | xargs -n 1 -I {} chmod ugo+r "{}"

RUN python -m compileall -q /app
RUN zip --quiet -9r /package.zip  .

# ------------------------------------------------------------------ package ---

FROM scratch as package

COPY --from=build /package.zip /tmp/
