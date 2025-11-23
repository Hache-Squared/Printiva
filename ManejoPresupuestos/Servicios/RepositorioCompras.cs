using Dapper;
using ManejoPresupuestos.Models;
using Microsoft.Data.SqlClient;

namespace ManejoPresupuestos.Servicios
{
    public interface IRepositorioCompras
    {
        Task<IEnumerable<Compra>> ObtenerTodos(int usuarioId);
        Task Crear(Compra compra);
        Task<Compra?> ObtenerPorId(int usuarioId, int id);
        Task Actualizar(int usuarioId, Compra compra);
        Task Borrar(int usuarioId, int id);
        Task CompraLogTransaccion(int usuarioId, Compra compra);
    }

    public class RepositorioCompras : IRepositorioCompras
    {
        private readonly string connectionString;
        public RepositorioCompras(IConfiguration configuration)
        {
            connectionString = configuration.GetConnectionString("DefaultConnection");
        }

        public async Task<IEnumerable<Compra>> ObtenerTodos(int usuarioId)
        {
            using var connection = new SqlConnection(connectionString);
            return await connection.QueryAsync<Compra>(
                "procObtenerCompras",
                new
                {
                    loginId = usuarioId
                },
                commandType: System.Data.CommandType.StoredProcedure
            );
        }

        public async Task Crear(Compra compra)
        {
            using var connection = new SqlConnection(connectionString);
            var id = await connection.QuerySingleAsync<int>(
                @"
                    INSERT INTO TblCompras (Descripcion, CompraTipoId, FilamentoTipoId, CostoTotal, CompraCategoriaId, FechaCreacion)
                    VALUES (@Descripcion, @CompraTipoId, @FilamentoTipoId, @CostoTotal, @CompraCategoriaId, @FechaCreacion);
                    SELECT SCOPE_IDENTITY();
                ",
                compra
            );

            compra.CompraId = id;
        }

        public async Task<Compra?> ObtenerPorId(int usuarioId, int id)
        {
            using var connection = new SqlConnection(connectionString);
            return await connection.QueryFirstOrDefaultAsync<Compra>(
                "procObtenerCompras",
                new
                {
                    elementoObtenerId = id,
                    loginId = usuarioId
                },
                commandType: System.Data.CommandType.StoredProcedure
            );
        }

        public async Task CompraLogTransaccion(int usuarioId, Compra compra)
        {
            using var connection = new SqlConnection(connectionString);
            await connection.QuerySingleAsync<int>(
                "procUpdateTransaccionesCompra",
                new
                {
                    Monto = compra.CostoTotal,
                    FechaTransaccion = compra.FechaCreacion,
                    UsuarioId = usuarioId,
                    
                },
                commandType: System.Data.CommandType.StoredProcedure
            );
        }

        public async Task Actualizar(int usuarioId, Compra compra)
        {
            using var connection = new SqlConnection(connectionString);
            await connection.QuerySingleAsync<Compra>(
                "procAlteraCompras",
                new
                {
                    elementoAlterarId = compra.CompraId,
                    descripcion = compra.Descripcion,
                    compraTipoId = compra.CompraTipoId,
                    filamentoTipoId = compra.FilamentoTipoId,
                    compraCategoriaId = compra.CompraCategoriaId,
                    costoTotal = compra.CostoTotal,
                    fechaCreacion = compra.FechaCreacion,
                    loginId = usuarioId,
                    actualizar = 1
                },
                commandType: System.Data.CommandType.StoredProcedure
            );
        }

        public async Task Borrar(int usuarioId, int id)
        {
            using var connection = new SqlConnection(connectionString);
            await connection.QueryFirstOrDefaultAsync<Compra>(
                "procAlteraCompras",
                new
                {
                    elementoAlterarId = id,
                    descripcion = "Compra eliminada",
                    loginId = usuarioId,
                    borrar = 1
                },
                commandType: System.Data.CommandType.StoredProcedure
            );
        }
    }
}
