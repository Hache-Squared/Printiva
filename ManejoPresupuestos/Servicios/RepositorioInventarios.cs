using Dapper;
using ManejoPresupuestos.Models;
using Microsoft.Data.SqlClient;

namespace ManejoPresupuestos.Servicios
{
    public interface IRepositorioInventarios
    {
        Task<IEnumerable<Inventario>> ObtenerTodos(int usuarioId);
        Task Crear(Inventario inventario);
        Task<Inventario?> ObtenerPorId(int usuarioId, int id);
        Task Actualizar(int usuarioId, Inventario inventario);
        Task Borrar(int usuarioId, int id);
    }

    public class RepositorioInventarios : IRepositorioInventarios
    {
        private readonly string connectionString;

        public RepositorioInventarios(IConfiguration configuration)
        {
            connectionString = configuration.GetConnectionString("DefaultConnection");
        }

        public async Task<IEnumerable<Inventario>> ObtenerTodos(int usuarioId)
        {
            using var connection = new SqlConnection(connectionString);
            return await connection.QueryAsync<Inventario>(
                "procObtenerInventarios",
                new
                {
                    loginId = usuarioId
                },
                commandType: System.Data.CommandType.StoredProcedure
            );
        }

        public async Task Crear(Inventario inventario)
        {
            using var connection = new SqlConnection(connectionString);
            var id = await connection.QuerySingleAsync<int>(
                @"
                    INSERT INTO TblInventarios (InventarioMarcaId, InventarioTipoId, InventarioNombreId, InventarioColorId, Cantidad, InventarioUnidadId, FechaCreacion)
                    VALUES (@InventarioMarcaId, @InventarioTipoId, @InventarioNombreId, @InventarioColorId, @Cantidad, @InventarioUnidadId, @FechaCreacion);

                    SELECT SCOPE_IDENTITY();
                ",
                inventario
            );

            inventario.InventarioId = id;
        }

        public async Task<Inventario?> ObtenerPorId(int usuarioId, int id)
        {
            using var connection = new SqlConnection(connectionString);
            return await connection.QueryFirstOrDefaultAsync<Inventario>(
                "procObtenerInventarios",
                new
                {
                    elementoObtenerId = id,
                    loginId = usuarioId
                },
                commandType: System.Data.CommandType.StoredProcedure
            );
        }

        public async Task Actualizar(int usuarioId, Inventario inventario)
        {
            using var connection = new SqlConnection(connectionString);
            await connection.QueryFirstOrDefaultAsync<Inventario>(
                "procActualizarRegistrosInventarios",
                new
                {
                    elementoAlterarId = inventario.InventarioId,
                    inventarioMarcaId = inventario.InventarioMarcaId,
                    inventarioTipoId = inventario.InventarioTipoId,
                    inventarioColorId = inventario.InventarioColorId,
                    cantidad = inventario.Cantidad,
                    inventarioUnidadId = inventario.InventarioUnidadId,
                    inventarioNombreId = inventario.InventarioNombreId,
                    loginId = usuarioId,
                    actualizar = 1
                },
                commandType: System.Data.CommandType.StoredProcedure
            );
        }

        public async Task Borrar(int usuarioId, int id)
        {
            using var connection = new SqlConnection(connectionString);
            await connection.QueryFirstOrDefaultAsync<Inventario>(
                "procActualizarRegistrosInventarios",
                new
                {
                    elementoAlterarId = id,
                    loginId = usuarioId,
                    borrar = 1
                },
                commandType: System.Data.CommandType.StoredProcedure
            );
        }
    }
}
