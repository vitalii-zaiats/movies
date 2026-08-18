"""One place where a refusal becomes a status code — gRPC's edition.

`api.main` has the same table for HTTP. Both exist because the services raise
domain errors and know nothing about either transport; neither table is allowed
to have an opinion the other doesn't.
"""

import grpc

from api.errors import CatalogueError, Conflict, Forbidden, Invalid, NotFound, Unauthorized

STATUS: dict[type[CatalogueError], grpc.StatusCode] = {
    NotFound: grpc.StatusCode.NOT_FOUND,
    Conflict: grpc.StatusCode.ALREADY_EXISTS,
    Invalid: grpc.StatusCode.INVALID_ARGUMENT,
    Unauthorized: grpc.StatusCode.UNAUTHENTICATED,
    Forbidden: grpc.StatusCode.PERMISSION_DENIED,
}


def code_for(error: CatalogueError) -> grpc.StatusCode:
    return STATUS.get(type(error), grpc.StatusCode.FAILED_PRECONDITION)


class Refusals(grpc.aio.ServerInterceptor):
    """Turns a raised `CatalogueError` into the status it deserves.

    An interceptor rather than a decorator on forty methods: a servicer that
    forgets the decorator would answer UNKNOWN and say nothing, which is the
    kind of bug that only shows up in somebody else's client.
    """

    async def intercept_service(self, continuation, handler_call_details):  # type: ignore[no-untyped-def]
        handler = await continuation(handler_call_details)
        if handler is None:
            return None

        if handler.unary_unary is not None:
            inner = handler.unary_unary

            async def unary(request, context):  # type: ignore[no-untyped-def]
                try:
                    return await inner(request, context)
                except CatalogueError as error:
                    await context.abort(code_for(error), str(error))

            return grpc.unary_unary_rpc_method_handler(
                unary,
                request_deserializer=handler.request_deserializer,
                response_serializer=handler.response_serializer,
            )

        if handler.unary_stream is not None:
            streaming = handler.unary_stream

            async def stream(request, context):  # type: ignore[no-untyped-def]
                try:
                    async for message in streaming(request, context):
                        yield message
                except CatalogueError as error:
                    await context.abort(code_for(error), str(error))

            return grpc.unary_stream_rpc_method_handler(
                stream,
                request_deserializer=handler.request_deserializer,
                response_serializer=handler.response_serializer,
            )

        return handler
